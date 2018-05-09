package haxeLanguageServer.features;

import jsonrpc.CancellationToken;
import jsonrpc.ResponseError;
import jsonrpc.Types.NoData;
import haxeLanguageServer.server.Protocol;

class GotoDefinitionFeature {
    var context:Context;

    public function new(context) {
        this.context = context;
        context.protocol.onRequest(Methods.GotoDefinition, onGotoDefinition);
    }

    public function onGotoDefinition(params:TextDocumentPositionParams, token:CancellationToken, resolve:Definition->Void, reject:ResponseError<NoData>->Void) {
        var doc = context.documents.get(params.textDocument.uri);
        var bytePos = context.displayOffsetConverter.characterOffsetToByteOffset(doc.content, doc.offsetAt(params.position));
        var handle = if (context.haxeServer.capabilities.definitionProvider) handleJsonRpc else handleLegacy;
        handle(params, token, resolve, reject, doc, bytePos);
    }

    function handleJsonRpc(params:TextDocumentPositionParams, token:CancellationToken, resolve:Definition->Void, reject:ResponseError<NoData>->Void, doc:TextDocument, bytePos:Int) {
        context.callHaxeMethod(HaxeMethods.GotoDefinition, {file: doc.fsPath, offset: bytePos}, token, locations -> {
            resolve(locations.map(location -> {
                {
                    uri: location.file.toUri(),
                    range: location.range
                }
            }));
        }, error -> reject(ResponseError.internalError(error)));
    }

    function handleLegacy(params:TextDocumentPositionParams, token:CancellationToken, resolve:Definition->Void, reject:ResponseError<NoData>->Void, doc:TextDocument, bytePos:Int) {
        var args = ['${doc.fsPath}@$bytePos@position'];
        context.callDisplay(args, doc.content, token, function(r) {
            switch (r) {
                case DCancelled:
                    resolve(null);
                case DResult(data):
                    var xml = try Xml.parse(data).firstElement() catch (_:Any) null;
                    if (xml == null) return reject(ResponseError.internalError("Invalid xml data: " + data));
                    var positions = [for (el in xml.elements()) el.firstChild().nodeValue];
                    if (positions.length == 0)
                        resolve([]);
                    var results = [];
                    for (pos in positions) {
                        var location = HaxePosition.parse(pos, doc, null, context.displayOffsetConverter); // no cache because this right now only returns one position
                        if (location == null) {
                            trace("Got invalid position: " + pos);
                            continue;
                        }
                        results.push(location);
                    }
                    resolve(results);
            }
        }, function(error) reject(ResponseError.internalError(error)));
    }
}
