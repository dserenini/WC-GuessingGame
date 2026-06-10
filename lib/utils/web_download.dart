import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

// ── Extension types para a Web Share API ────────────────────────────────────

/// Representa o objeto ShareData esperado pelo navigator.share()
extension type _ShareData._(JSObject _) implements JSObject {
  external factory _ShareData({
    String? text,
    JSArray<JSObject>? files,
  });
}

/// Wrapper para acessar métodos de share via JS interop
@JS('navigator')
external JSObject get _jsNavigator;

@JS('navigator.share')
external JSFunction? get _jsShare;

@JS('navigator.canShare')
external JSFunction? get _jsCanShare;

// ── Download ─────────────────────────────────────────────────────────────────

void downloadImage(Uint8List bytes, String filename) {
  downloadBytes(bytes, filename, 'image/png');
}

/// Faz o download de [bytes] como um arquivo [filename] com o [mimeType] dado.
void downloadBytes(Uint8List bytes, String filename, String mimeType) {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = filename
    ..style.display = 'none';

  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}

// ── Web Share API ─────────────────────────────────────────────────────────────

/// Compartilha a imagem via Web Share API (seletor nativo do SO no mobile).
/// Retorna true se conseguiu compartilhar, false se a API não estiver disponível.
Future<bool> shareImageNative(
  Uint8List bytes,
  String filename,
  String text,
) async {
  // Verifica suporte à Web Share API
  if (_jsShare == null || _jsCanShare == null) return false;

  try {
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'image/png'),
    );

    final file = web.File(
      [blob].toJS,
      filename,
      web.FilePropertyBag(type: 'image/png'),
    );

    final shareData = _ShareData(
      text: text,
      files: [file as JSObject].toJS,
    );

    // Verifica se o navegador suporta compartilhar esse tipo de arquivo
    final canShare = _jsCanShare!.callAsFunction(_jsNavigator, shareData);
    if (canShare == null) return false;
    if (!(canShare as JSBoolean).toDart) return false;

    // Executa o share — retorna uma Promise
    final promise = _jsShare!.callAsFunction(_jsNavigator, shareData);
    if (promise == null) return false;
    await (promise as JSPromise<JSAny?>).toDart;

    return true;
  } catch (_) {
    return false;
  }
}
