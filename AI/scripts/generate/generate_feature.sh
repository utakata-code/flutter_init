#!/bin/bash
# ⚠️  このスクリプトは非推奨です。代わりに utakata CLI を使用してください。
# Deprecated: Use `utakata feature add` instead.

echo ""
echo "⚠️  このスクリプトは非推奨です。"
echo ""
echo "代わりに以下のコマンドを使用してください:"
echo ""
echo "  utakata feature add <feature_name> [--permission user|admin|shared|direct]"
echo ""
echo "例:"
echo "  utakata feature add memo"
echo "  utakata feature add auth --permission shared"
echo ""
echo "インストール: dart pub global activate utakata"
echo ""
exit 0
