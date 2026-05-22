import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../1_domain/2_repositories/arch_definition_repository.dart';
import '../../1_domain/3_usecases/load_arch_definition_usecase.dart';
import '../../2_infrastructure/2_data_sources/1_local/arch_definition_local_data_source.dart';
import '../../2_infrastructure/3_repositories/arch_definition_repository_impl.dart';
import '../../../validation/3_application/2_providers/validation_providers.dart';

/// arch_viewer DI プロバイダ
final archLocalDataSourceProvider = Provider<ArchDefinitionLocalDataSource>(
  (ref) => ArchDefinitionLocalDataSource(),
);

final archRepositoryProvider = Provider<ArchDefinitionRepository>(
  (ref) => ArchDefinitionRepositoryImpl(ref.read(archLocalDataSourceProvider)),
);

final loadArchDefinitionUsecaseProvider = Provider<LoadArchDefinitionUsecase>(
  (ref) => LoadArchDefinitionUsecase(
    ref.read(archRepositoryProvider),
    ref.read(validateYamlUsecaseProvider),
  ),
);
