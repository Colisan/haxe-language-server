package haxeLanguageServer.protocol;

import haxe.display.Display;
import haxe.display.JsonModuleTypes;
import haxeLanguageServer.helper.IdentifierHelper;

using Lambda;

function getDocumentation<T>(item:DisplayItem<T>):JsonDoc {
	return switch item.kind {
		case ClassField | EnumAbstractField: item.args.field.doc;
		case EnumField: item.args.field.doc;
		case Type: item.args.doc;
		case Metadata: new DisplayPrinter().printMetadataDetails(item.args);
		case _: null;
	}
}

function extractFunctionSignature<T>(type:JsonType<T>) {
	return switch removeNulls(type).type {
		case {kind: TFun, args: args}: args;
		case _: throw "function expected";
	}
}

function resolveImports<T>(type:JsonType<T>):Array<JsonTypePath> {
	function rec(type:JsonType<T>):Array<JsonTypePath> {
		return switch type.kind {
			case TMono:
				[];
			case TInst | TEnum | TType | TAbstract:
				var paths = [];
				final typePath:JsonTypePathWithParams = type.args;
				if (typePath.params != null) {
					paths = typePath.params.map(rec).flatten().array();
				}
				if (typePath.path.importStatus == Unimported) {
					paths.push(typePath.path);
				}
				paths;
			case TFun:
				final signature = type.args;
				signature.args.map(arg -> rec(arg.t)).flatten().array().concat(rec(signature.ret));
			case TAnonymous:
				type.args.fields.map(field -> rec(field.type)).flatten().array();
			case TDynamic:
				if (type.args != null) {
					rec(type.args);
				} else {
					[];
				}
		}
	}
	return rec(type);
}

// TODO: respect abstract implication conversions here somehow?
function resolveTypes<T>(type:JsonType<T>):Array<JsonType<T>> {
	switch type.kind {
		case TAbstract:
			if (type.getDotPath() == Haxe_Extern_EitherType) {
				return (type.args : JsonTypePathWithParams).params.map(resolveTypes).flatten().array();
			}
		case _:
	}
	return [type];
}

function hasMeta(?meta:JsonMetadata, name:CompilerMetadata) {
	return meta != null && meta.exists(meta -> meta.name == cast name);
}

function isOperator(field:JsonClassField) {
	return field.meta.hasMeta(Op) || field.meta.hasMeta(Resolve) || field.meta.hasMeta(ArrayAccess);
}

function isEnumAbstractField(field:JsonClassField) {
	return field.meta.hasMeta(Enum) && switch field.kind.kind {
		case FVar:
			final writeAccess:JsonVarAccess<Dynamic> = field.kind.args.write;
			writeAccess.kind == AccNever;
		case FMethod: false;
	};
}

inline function isVoid<T>(type:JsonType<T>) {
	return type.getDotPath() == Std_Void;
}

function isModuleLevel<T>(origin:Null<ClassFieldOrigin<T>>) {
	if (origin == null) {
		return false;
	}
	return switch origin.kind {
		case Self | Parent | StaticImport | StaticExtension:
			final moduleType:Null<JsonModuleType<Dynamic>> = origin.args;
			if (moduleType == null) {
				return false;
			}
			switch moduleType.kind {
				case Class:
					final cl:JsonClass = moduleType.args;
					cl.kind.kind == KModuleFields;
				case _: false;
			}
		case _: false;
	}
}

function isStructure<T>(origin:Null<ClassFieldOrigin<T>>) {
	if (origin == null) {
		return false;
	}
	return switch origin.kind {
		case Self | StaticImport | Parent | StaticExtension:
			final moduleType:Null<JsonModuleType<Dynamic>> = origin.args;
			if (moduleType == null) {
				return false;
			}
			switch moduleType.kind {
				case Typedef:
					final jsonTypedef:JsonTypedef = moduleType.args;
					jsonTypedef.type.removeNulls().type.kind == TAnonymous;
				case _: false;
			}
		case AnonymousStructure: true;
		case _: false;
	}
	return false;
}

function removeNulls<T>(type:JsonType<T>, nullable:Bool = false):{type:JsonType<T>, nullable:Bool} {
	switch type.kind {
		case TAbstract:
			final path:JsonTypePathWithParams = type.args;
			if (type.getDotPath() == Std_Null) {
				if (path.params != null && path.params[0] != null) {
					return removeNulls(path.params[0], true);
				}
			}
		case _:
	}
	return {type: type, nullable: nullable};
}

function getTypePath<T>(type:JsonType<T>):Null<JsonTypePathWithParams> {
	return switch type.kind {
		case null: null;
		case TInst | TEnum | TType | TAbstract: type.args;
		case _: null;
	}
}

function guessName<T>(type:JsonType<T>):String {
	final path = type.getTypePath();
	if (path == null) {
		return "unknown";
	}
	return IdentifierHelper.guessName(path.path.typeName);
}

function hasMandatoryTypeParameters(type:DisplayModuleType):Bool {
	// Dynamic is a special case regarding this in the compiler
	if (type.path.getDotPath2() == Std_Dynamic) {
		return false;
	}
	return type.params != null && type.params.length > 0;
}

function isFinalField(field:JsonClassField) {
	return field.meta.hasMeta(Final) || field.isFinal;
}

function isFinalType(type:DisplayModuleType) {
	return type.meta.hasMeta(Final) || type.isFinal;
}
