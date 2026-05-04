import '../1_entities/architecture_diff_entity.dart';
import '../messages/cli_messages.dart';
import 'diff_architecture_usecase.dart';

/// アーキテクチャの健全性チェックを行うユースケース
class CheckStructureUsecase {
  final DiffArchitectureUsecase _diffUsecase;

  const CheckStructureUsecase({
    required DiffArchitectureUsecase diffUsecase,
    // CliMessages は diff usecase 側で使用するため、ここでは保持しない
    required CliMessages msg,
  }) : _diffUsecase = diffUsecase;

  /// 健全性チェックを実行する
  Future<ArchitectureDiffEntity> execute(String projectDir) async {
    return _diffUsecase.execute(projectDir);
  }
}
