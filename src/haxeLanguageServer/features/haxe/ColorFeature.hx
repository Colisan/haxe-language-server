package haxeLanguageServer.features.haxe;

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
		resolve([
			{
				label: "0xTODOTODO"
			}
		]);
	}
}
