import 'package:test/test.dart';
import 'package:utakata/src/1_domain/3_usecases/show_doc_usecase.dart';
import 'package:utakata/src/2_infrastructure/2_data_sources/1_local/filesystem_data_source.dart';

void main() {
  const fs = FilesystemDataSource();
  final usecase = ShowDocUsecase(
    resolvePackageFilePath: fs.resolvePackageFilePath,
    readFile: fs.readFile,
  );

  test('同梱ドキュメントがパッケージ経由で解決できる', () async {
    for (final topic in ShowDocUsecase.topics.keys) {
      final content = await usecase.execute(topic);
      expect(content, isNotNull, reason: 'topic "$topic" のファイルが同梱されていない');
      expect(content!.length, greaterThan(200));
    }
  });

  test('未知のトピックは null', () async {
    expect(await usecase.execute('no-such-topic'), isNull);
  });

  test('全トピックに説明文が付いている', () {
    expect(ShowDocUsecase.descriptions.keys.toSet(),
        ShowDocUsecase.topics.keys.toSet());
  });
}
