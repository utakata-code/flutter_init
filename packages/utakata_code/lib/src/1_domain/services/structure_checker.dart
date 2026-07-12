import '../1_entities/structure/check_report.dart';
import '../1_entities/structure/expected_structure.dart';
import '../1_entities/structure/structure_node.dart';
import '../1_entities/structure/structure_snapshot.dart';

/// [ExpectedStructure] と [StructureSnapshot] を1回の走査で比較する純関数サービス。
///
/// 旧 `diff_architecture_usecase`(構造差分)と `validate_usecase`(命名違反)を
/// 統合する(仕様書 §5)。ディレクトリ単位で「まるごと欠落/余分」を報告し、
/// 存在するディレクトリの中身についてのみファイル単位の要否・命名を判定する。
abstract final class StructureChecker {
  static CheckReport check(ExpectedStructure expected, StructureSnapshot snapshot) {
    final missing = <String>[];
    final extra = <String>[];
    final violations = <NamingViolation>[];

    _compareLevel(
      expected.topLevel,
      snapshot.root.children,
      '',
      missing,
      extra,
      violations,
    );

    missing.sort();
    extra.sort();
    violations.sort((a, b) => a.filePath.compareTo(b.filePath));

    return CheckReport(
      missingPaths: missing,
      extraPaths: extra,
      namingViolations: violations,
    );
  }

  static void _compareLevel(
    Map<String, ExpectedDir> expectedChildren,
    Map<String, StructureNode> actualChildren,
    String pathPrefix,
    List<String> missing,
    List<String> extra,
    List<NamingViolation> violations,
  ) {
    for (final entry in expectedChildren.entries) {
      final name = entry.key;
      final expectedDir = entry.value;
      final fullPath = pathPrefix.isEmpty ? name : '$pathPrefix/$name';
      final actualNode = actualChildren[name];

      if (actualNode is! StructureDirNode) {
        missing.add(fullPath);
        continue;
      }

      final actualFileNames = actualNode.fileNames;

      for (final requiredFile in expectedDir.requiredFiles) {
        if (!actualFileNames.contains(requiredFile)) {
          missing.add('$fullPath/$requiredFile');
        }
      }

      for (final fileName in actualFileNames) {
        final fileNode = actualNode.children[fileName];
        if (fileNode is StructureFileNode && fileNode.isGenerated) continue;
        if (expectedDir.requiredFiles.contains(fileName)) continue;

        final rule = expectedDir.allowRule;
        if (rule != null) {
          if (!rule.regex.hasMatch(fileName)) {
            violations.add(NamingViolation(
              filePath: '$fullPath/$fileName',
              expectedPattern: rule.description,
            ));
          }
          // regex に合致すれば、命名が非決定的なディレクトリでも許可する
          // (allowRules 方式。既知バグ「常に extra 誤検知」の解消)。
        } else {
          extra.add('$fullPath/$fileName');
        }
      }

      _compareLevel(
        expectedDir.children,
        actualNode.children,
        fullPath,
        missing,
        extra,
        violations,
      );
    }

    for (final entry in actualChildren.entries) {
      final name = entry.key;
      if (expectedChildren.containsKey(name)) continue;
      final node = entry.value;
      if (node is! StructureDirNode) continue; // 対応する expectedDir がない階層の孤立ファイルは exceptional case として extra 扱い済み(上のループの管轄外)
      final fullPath = pathPrefix.isEmpty ? name : '$pathPrefix/$name';
      extra.add(fullPath);
    }
  }
}
