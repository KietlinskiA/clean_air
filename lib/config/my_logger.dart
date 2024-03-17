import 'dart:io';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:clean_air/config/app_config.dart';
import 'package:path_provider/path_provider.dart';

class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  final Logger _logger;

  factory AppLogger() {
    return _instance;
  }

  AppLogger._internal()
      : _logger = Logger(
          level: AppConfig.logLevel,
          filter: DevelopmentFilter(),
          printer: SimplePrinter(printTime: true, colors: false),
          output: MultiOutput([
            ConsoleOutput(),
            FileOutput(),
          ]),
        );

  Logger get logger => _logger;
}

class FileOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    getFileOutput().then((Directory directory) {
      String fileName =
          'log_${DateFormat('yyyyMMdd').format(DateTime.now())}.txt';
      File file = File('${directory.path}/$fileName');
      file.writeAsStringSync('${event.lines.join("\n")}\n',
          mode: FileMode.append);
    });
  }

  Future<Directory> getFileOutput() async {
    Directory appDocDirectory = await getApplicationDocumentsDirectory();
    return Directory('${appDocDirectory.path}/logs').create(recursive: true);
  }
}
