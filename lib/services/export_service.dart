import 'export_stub.dart' if (dart.library.html) 'export_web.dart';

Future<void> downloadCsv({required String filename, required String csv}) {
  return exportCsv(filename: filename, csv: csv);
}
