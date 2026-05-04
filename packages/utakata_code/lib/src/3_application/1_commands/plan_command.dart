import 'dart:io';

import '../../1_domain/3_usecases/plan_architecture_usecase.dart';
import '../../1_domain/messages/cli_messages.dart';
import 'base_command.dart';
import 'logger.dart';

/// utakata plan — feature_request.yaml から plan_architecture.yaml を生成
class PlanCommand extends BaseCommand {
  final PlanArchitectureUsecase _usecase;
  final CliMessages _msg;

  @override
  String get name => 'plan';

  @override
  String get description => _msg.cmdPlanDesc;

  PlanCommand(this._usecase, this._msg);

  @override
  Future<int> execute() async {
    Logger.section(_msg.sectionPlan);
    final plan = await _usecase.execute(Directory.current.path);
    final featureCount = _countFeatures(plan);
    Logger.success(_msg.planDone(featureCount));
    return 0;
  }

  int _countFeatures(Map<String, dynamic> plan) {
    try {
      final features = plan['features'] as Map?;
      if (features == null) return 0;
      return features.values.fold<int>(
        0,
        (acc, v) => acc + (v is Map ? v.length : 0),
      );
    } catch (_) {
      return 0;
    }
  }
}
