import 'package:web/web.dart' as web;

void downloadCsv(String filename, String content) {
  final encoded = Uri.encodeComponent(content);
  final a = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = 'data:text/csv;charset=utf-8,$encoded'
    ..download = filename;
  web.document.body?.append(a);
  a.click();
  a.remove();
}