package haxeLanguageServer.extensions;

inline function occurrences(s:String, of:String) {
	return s.length - s.replace(of, "").length;
}

function untilLastDot(s:String) {
	final dotIndex = s.lastIndexOf(".");
	if (dotIndex == -1)
		return s;
	return s.substring(0, dotIndex);
}

function untilFirstDot(s:String) {
	final dotIndex = s.indexOf(".");
	if (dotIndex == -1)
		return s;
	return s.substring(0, dotIndex);
}

function afterLastDot(s:String) {
	final dotIndex = s.lastIndexOf(".");
	if (dotIndex == -1)
		return s;
	return s.substr(dotIndex + 1);
}

function last(s:String):String {
	return s.charAt(s.length - 1);
}

function capitalize(s:String):String {
	return s.charAt(0).toUpperCase() + s.substr(1);
}
