import 'dart:typed_data';

void downloadImage(Uint8List bytes, String filename) {
  throw UnsupportedError('Cannot download directly on this platform');
}

Future<bool> shareImageNative(Uint8List bytes, String filename, String text) async {
  return false; // Não suportado fora da web
}

