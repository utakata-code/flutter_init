import '../../../../1_domain/exceptions/validation_exception.dart';

/// ファイル監視関連の例外
class FileWatcherException extends ValidationException {
  const FileWatcherException(super.message);
}
