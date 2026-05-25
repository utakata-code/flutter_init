# 推奨パッケージカタログ (Recommended Packages)

アプリの機能に応じて選択する推奨パッケージの一覧です。
基盤パッケージ（全プロジェクト共通）は [technology_stack.md](technology_stack.md) を参照してください。

> ここに記載されたパッケージは**必須ではありません**。
> 実装する機能に応じて必要なものだけを `pubspec.yaml` に追加してください。

---

## 🌐 HTTP通信・API連携

| パッケージ | 用途 | 補足 |
|-----------|------|------|
| `http` | 基本的なHTTP通信 | 軽量、シンプルなREST API向け |
| `dio` | 高機能HTTP通信 | インターセプター、キャンセル、リトライ等が必要な場合 |

**選定ガイド**:
- シンプルなAPI呼び出しのみ → `http`
- 認証トークンの自動付与、リトライ、ログ出力等が必要 → `dio`

---

## 🔐 認証・セキュリティ

| パッケージ | 用途 |
|-----------|------|
| `google_sign_in` | Google アカウント認証 |
| `googleapis` | Google API クライアント |
| `googleapis_auth` | Google API 認証ヘルパー |
| `extension_google_sign_in_as_googleapis_auth` | google_sign_in と googleapis_auth の橋渡し |
| `flutter_secure_storage` | 暗号化されたデータ保存（トークン等） |

**使用例**: Google Drive 連携、Google Sheets 連携、OAuthフロー

---

## 💾 データ保存（Drift以外）

| パッケージ | 用途 | 補足 |
|-----------|------|------|
| `shared_preferences` | 簡易Key-Valueストア | 設定値、フラグ、小さなデータ向け |

**選定ガイド**:
- アプリ設定、ユーザー設定の保存 → `shared_preferences`
- 構造化データ、リレーション、クエリが必要 → 基盤の `drift` を使用

---

## 🌍 WebView・ブラウザ

| パッケージ | 用途 | 補足 |
|-----------|------|------|
| `flutter_inappwebview` | アプリ内ブラウザ | JS実行、Cookie管理、カスタムUI対応 |
| `url_launcher` | 外部ブラウザでURL起動 | メール・電話リンクにも対応 |

---

## 📱 ネットワーク・接続

| パッケージ | 用途 |
|-----------|------|
| `connectivity_plus` | ネットワーク接続状態の監視（WiFi / モバイル / なし） |

**使用例**: オフラインモード対応、接続復帰時の自動同期

---

## 🖥️ デスクトップ対応

| パッケージ | 用途 | 対象OS |
|-----------|------|--------|
| `flutter_single_instance` | 多重起動防止 | Windows / macOS |
| `window_manager` | ウィンドウサイズ・位置・タイトルバー制御 | Windows / macOS |
| `macos_window_utils` | macOS専用のウィンドウ制御（透明化等） | macOS |

---

## 🕷️ スクレイピング・HTMLパース

| パッケージ | 用途 | 補足 |
|-----------|------|------|
| `html` | HTMLパース | DOM操作、要素抽出 |
| `http` | HTMLの取得 | 上記「HTTP通信」セクション参照 |

---

## 🧪 テスト

| パッケージ | 用途 | 種別 |
|-----------|------|------|
| `mockito` | モックオブジェクト生成 | dev_dependency |
| `integration_test` | 統合テスト（SDK付属） | dev_dependency |

---

## 🎨 ビルド・配布

| パッケージ | 用途 | 種別 |
|-----------|------|------|
| `flutter_launcher_icons` | アプリアイコンの自動生成 | dev_dependency |

**使い方**:
```yaml
# pubspec.yaml に設定を追加
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
```

```bash
dart run flutter_launcher_icons
```

---

## パッケージ追加時の注意

1. **構造計画書との同期**: 新しいパッケージを追加した場合は `AI/specs/structure_plan.md` に影響を反映してください。
2. **バージョン指定**: `^x.y.z` 形式で最低バージョンを指定し、マイナーバージョンの自動更新を許容してください。
3. **プラットフォーム対応**: デスクトップ専用パッケージは、モバイル向けビルド時に影響がないか確認してください。
