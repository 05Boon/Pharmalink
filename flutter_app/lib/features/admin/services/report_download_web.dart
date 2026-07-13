import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'dart:typed_data';

void downloadBytes(Uint8List bytes, String filename, String mimeType) {
  // Convert Uint8List to JSArray (JSUint8Array)
  final jsBytes = bytes.toJS;
  
  // Build a temporary browser object URL for the exported bytes.
  // Blob constructor expects a JSArray of BlobParts.
  final blobParts = [jsBytes].toJS;
  final blob = web.Blob(blobParts, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none';

  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}

