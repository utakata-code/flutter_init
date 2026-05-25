import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../1_domain/2_repositories/yaml_parser_repository.dart';
import '../../1_domain/3_usecases/validate_yaml_usecase.dart';
import '../../2_infrastructure/2_data_sources/1_local/yaml_file_watcher_data_source.dart';
import '../../2_infrastructure/3_repositories/validation_repository_impl.dart';
import '../../2_infrastructure/3_repositories/yaml_parser_repository_impl.dart';
import '../../1_domain/2_repositories/validation_repository.dart';

/// バリデーション DI プロバイダ

final yamlParserRepositoryProvider = Provider<YamlParserRepository>(
  (ref) => const YamlParserRepositoryImpl(),
);

final validateYamlUsecaseProvider = Provider<ValidateYamlUsecase>(
  (ref) => ValidateYamlUsecase(ref.read(yamlParserRepositoryProvider)),
);

final yamlFileWatcherProvider = Provider<YamlFileWatcherDataSource>(
  (ref) => YamlFileWatcherDataSource(),
);

final validationRepositoryProvider = Provider<ValidationRepository>(
  (ref) => ValidationRepositoryImpl(ref.read(yamlFileWatcherProvider)),
);
