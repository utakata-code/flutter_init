import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../main.dart';
import '../../1_domain/3_usecases/validate_yaml_usecase.dart';
import '../3_notifiers/yaml_validation_notifier.dart';

/// ValidateYamlUsecase のプロバイダ
final validateYamlUsecaseProvider = Provider<ValidateYamlUsecase>(
  (ref) => const ValidateYamlUsecase(),
);

/// YamlValidationNotifier のプロバイダ
final yamlValidationProvider =
    StateNotifierProvider<YamlValidationNotifier, YamlValidationState>(
  (ref) {
    final usecase = ref.read(validateYamlUsecaseProvider);
    final projectRoot = ref.read(projectRootProvider);
    return YamlValidationNotifier(usecase, projectRoot);
  },
);
