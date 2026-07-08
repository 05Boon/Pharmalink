import 'dart:typed_data';

void downloadBytes(Uint8List bytes, String filename, String mimeType) {
  // Non-web builds currently do not wire native file pick/save flows.
  throw UnsupportedError('Report download is currently supported on web only.');
}
