import '../1_entities/structure/structure_snapshot.dart';

/// `lib/features/` の実構造を読み取るリポジトリのインターフェース。
///
/// スナップショットは永続化しない(P1)。毎回その場でスキャンする。
abstract interface class StructureRepository {
  Future<StructureSnapshot> scan(String projectDir);
}
