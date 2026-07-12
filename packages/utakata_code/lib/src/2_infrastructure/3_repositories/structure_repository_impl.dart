import 'package:path/path.dart' as p;

import '../../1_domain/1_entities/structure/structure_snapshot.dart';
import '../../1_domain/2_repositories/structure_repository.dart';
import '../2_data_sources/1_local/filesystem_data_source.dart';

class StructureRepositoryImpl implements StructureRepository {
  final FilesystemDataSource _fs;

  const StructureRepositoryImpl(this._fs);

  @override
  Future<StructureSnapshot> scan(String projectDir) async {
    final featuresDir = p.join(projectDir, 'lib', 'features');
    final root = _fs.scanStructureTree(featuresDir);
    return StructureSnapshot(root: root, scannedAt: DateTime.now());
  }
}
