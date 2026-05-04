import '../../1_domain/1_entities/project_spec_entity.dart';
import '../../1_domain/3_usecases/create_project_usecase.dart';
import '../../1_domain/messages/cli_messages.dart';
import 'base_command.dart';
import 'logger.dart';

/// utakata create — Flutter プロジェクトを新規作成する
class CreateCommand extends BaseCommand {
  final CreateProjectUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'create';

  @override
  String get description => _msg.cmdCreateDesc;

  CreateCommand(this._usecase, this._msg) {
    argParser
      ..addOption('org',
          abbr: 'o',
          defaultsTo: 'com.example',
          help: _msg.optOrg)
      ..addOption('platforms',
          defaultsTo: 'android,ios,web,macos',
          help: _msg.optPlatforms)
      ..addOption('description',
          abbr: 'd',
          defaultsTo: 'Flutter app',
          help: _msg.optDescription)
      ..addOption('arch',
          defaultsTo: 'clean_architecture',
          help: _msg.optArch);
  }

  @override
  Future<int> execute() async {
    if (argResults!.rest.isEmpty) {
      Logger.error(_msg.missingAppName);
      return 1;
    }

    final appName = argResults!.rest.first;
    final projectName = _toSnakeCase(appName);

    Logger.section(_msg.sectionCreate(appName));

    final spec = ProjectSpecEntity(
      appName: appName,
      projectName: projectName,
      org: argResults!['org'] as String,
      platforms: argResults!['platforms'] as String,
      description: argResults!['description'] as String,
      architectureId: argResults!['arch'] as String,
    );

    await _usecase.execute(spec);
    Logger.success(_msg.projectCreated(appName));
    return 0;
  }

  String _toSnakeCase(String input) => input
      .replaceAll(RegExp(r'[\s\-]'), '_')
      .replaceAllMapped(
        RegExp(r'[A-Z]'),
        (m) => '_${m[0]!.toLowerCase()}',
      )
      .toLowerCase()
      .replaceAll(RegExp(r'^_+|_+$'), '');
}
