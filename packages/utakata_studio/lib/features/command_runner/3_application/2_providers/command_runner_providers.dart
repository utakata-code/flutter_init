import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/cli_bridge/cli_bridge_provider.dart';
import '../../1_domain/2_repositories/command_runner_repository.dart';
import '../../1_domain/3_usecases/run_command_usecase.dart';
import '../../2_infrastructure/2_data_sources/1_local/command_runner_local_data_source.dart';
import '../../2_infrastructure/3_repositories/command_runner_repository_impl.dart';

/// DataSource Provider
final commandRunnerLocalDataSourceProvider =
    Provider<CommandRunnerLocalDataSource>((ref) {
  final bridge = ref.watch(cliBridgeProvider);
  return CommandRunnerLocalDataSource(bridge);
});

/// Repository Provider
final commandRunnerRepositoryProvider =
    Provider<CommandRunnerRepository>((ref) {
  final dataSource = ref.watch(commandRunnerLocalDataSourceProvider);
  return CommandRunnerRepositoryImpl(dataSource);
});

/// UseCase Provider
final runCommandUsecaseProvider = Provider<RunCommandUsecase>((ref) {
  final repository = ref.watch(commandRunnerRepositoryProvider);
  return RunCommandUsecase(repository);
});
