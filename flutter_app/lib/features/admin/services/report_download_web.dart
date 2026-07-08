import 'dart:html' as html;
import 'dart:typed_data';

void downloadBytes(Uint8List bytes, String filename, String mimeType) {
  // Build a temporary browser object URL for the exported bytes.
  final blob = html.Blob(<dynamic>[bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';

  // Trigger a synthetic click to start the download and clean up.
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
