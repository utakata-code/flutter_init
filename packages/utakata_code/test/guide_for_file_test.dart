import 'package:test/test.dart';
import 'package:utakata/src/1_domain/3_usecases/guide_for_file_usecase.dart';

void main() {
  group('GuideForFileUsecase.layerPathOf', () {
    test('resolves layer path under a permission dir', () {
      expect(
        GuideForFileUsecase.layerPathOf(
            'lib/features/user/todo/1_domain/1_entities/todo_entity.dart'),
        '1_domain/1_entities',
      );
    });

    test('resolves nested layer path (exceptions subdir)', () {
      expect(
        GuideForFileUsecase.layerPathOf(
            'lib/features/admin/report/2_infrastructure/2_data_sources/1_local/exceptions/report_local_exceptions.dart'),
        '2_infrastructure/2_data_sources/1_local/exceptions',
      );
    });

    test('direct permission (feature directly under features/) skips one segment', () {
      expect(
        GuideForFileUsecase.layerPathOf(
            'lib/features/onboarding/1_domain/1_entities/user_entity.dart'),
        '1_domain/1_entities',
      );
    });

    test('absolute path works (marker search)', () {
      expect(
        GuideForFileUsecase.layerPathOf(
            '/home/dev/app/lib/features/user/todo/1_domain/3_usecases/get_todo_usecase.dart'),
        '1_domain/3_usecases',
      );
    });

    test('outside lib/features returns null', () {
      expect(GuideForFileUsecase.layerPathOf('lib/core/routing/app_router.dart'), isNull);
      expect(GuideForFileUsecase.layerPathOf('lib/main.dart'), isNull);
    });

    test('file directly under a feature returns null', () {
      expect(GuideForFileUsecase.layerPathOf('lib/features/user/todo/README.md'), isNull);
    });
  });
}
