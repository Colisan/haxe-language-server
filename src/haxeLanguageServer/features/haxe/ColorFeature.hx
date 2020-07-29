package haxeLanguageServer.features.haxe;

import StringTools;
import jsonrpc.CancellationToken;
import jsonrpc.ResponseError;
import jsonrpc.Types.NoData;
import languageServerProtocol.protocol.ColorProvider.ColorPresentationParams;
import languageServerProtocol.protocol.ColorProvider.ColorPresentationRequest;
import languageServerProtocol.protocol.ColorProvider.DocumentColorParams;
import languageServerProtocol.protocol.ColorProvider.DocumentColorRequest;

class ColorFeature {
	final context:Context;

	public function new(context) {
		this.context = context;
		context.languageServerProtocol.onRequest(DocumentColorRequest.type, onColor);
		context.languageServerProtocol.onRequest(ColorPresentationRequest.type, onPresentation);
	}

	public function onColor(params:DocumentColorParams, token:CancellationToken, resolve:Array<ColorInformation>->Void, reject:ResponseError<NoData>->Void) {
		resolve([
			{
				range: {start: {line: 10, character: 49}, end: {line: 10, character: 59}},
				color: {
					red: 1,
					green: 0,
					blue: 0,
					alpha: 1
				}
			}
		]);
	}

	public function onPresentation(params:ColorPresentationParams, token:CancellationToken, resolve:Array<ColorPresentation>->Void,
			reject:ResponseError<NoData>->Void) {
		final colStr:String = "0x";
		if (params.color.alpha == 1) {
			colStr += StringTools.hex(colorTo3ChannelInt(params.color), 6);
		} else {
			colStr += StringTools.hex(colorTo4ChannelInt(params.color), 8);
		}
		resolve([
			{
				label: colStr
			}
		]);
	}

	public static function colorTo4ChannelInt(col:Color):Int {
		final a:Int = Std.int(col.alpha * 255);
		return (a << 24) | colorTo3ChannelInt(col);
	}

	public static function colorTo3ChannelInt(col:Color):Int {
		final r:Int = Std.int(col.red * 255);
		final g:Int = Std.int(col.green * 255);
		final b:Int = Std.int(col.blue * 255);
		return (r << 16) | (g << 8) | b;
	}
}
