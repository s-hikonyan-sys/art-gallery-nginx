# art-gallery-nginx

![Nginx](https://img.shields.io/badge/Web_Server-Nginx-009639) ![CI](https://img.shields.io/badge/CI-GitHub_Actions-2088FF)

アートギャラリー Web アプリケーションの Nginx 設定リポジトリです。

## 概要

本番環境で使用する Nginx 設定ファイルを管理します。マルチレポ構成における Nginx コンポーネントとして独立管理されます。

Docker イメージのビルドは行わず、公式の `nginx:alpine` イメージを使用します。`nginx.conf` はボリュームマウントで提供し、設定変更時は `nginx -s reload` によるゼロダウンタイムのホットリロードで反映します。

`main` ブランチへの push をトリガーに CI が設定ファイルの構文チェックを行い、`art-gallery-release-tools` の `deploy_nginx.yml` を自動トリガーしてサーバーへデプロイします。

## ディレクトリ構成

```
art-gallery-nginx/
├── nginx.conf          # 本番用 Nginx 設定
├── nginx.dev.conf      # 開発環境用 Nginx 設定
├── Makefile            # lint ターゲット
├── .nginx-lint.sh      # 構文チェックスクリプト
└── .github/
    └── workflows/
        └── ci.yml      # CI ワークフロー
```

## 設定の概要（nginx.conf）

| 設定項目 | 内容 |
|:---|:---|
| リッスンポート | 80 |
| ドキュメントルート | `/usr/share/nginx/html`（Frontend の `dist/` をマウント） |
| API プロキシ | `location /api` → `http://backend:8080` |
| SPA 対応 | `try_files $uri $uri/ /index.html` |
| 静的アセットキャッシュ | `.js/.css/画像` → `Cache-Control: public, immutable, 1y` |
| Gzip 圧縮 | 有効（1KB 以上のテキスト系 MIME タイプ） |
| セキュリティ | 危険なパス・拡張子（`.yaml`, `.env`, `.py` 等）を 404 で拒否 |

## ローカル構文チェック

Docker が使用可能な環境で実行してください。

```bash
make lint
```

内部では `nginx:latest` コンテナを使って `nginx -t` を実行します。

## CI / デプロイフロー

```
git push → main
    ↓
ci.yml
  1. make lint（nginx -t で構文チェック）
  2. gh api → deploy_nginx.yml をトリガー
              (nginx_ref = commit sha を渡す)
```

デプロイ先での処理（`art-gallery-release-tools` 側）:
- `nginx.conf` を git pull でサーバーへ取得（`/opt/art-gallery/src/art-gallery-nginx/`）
- `conf/nginx/nginx.conf` へコピー
- `nginx -t` で再度構文チェック
- `nginx -s reload` でホットリロード（コンテナ再起動なし）

## GitHub Settings

本リポジトリに以下の Secret の登録が必要です。

| 種別 | 変数名 | 内容 |
|:---|:---|:---|
| Secret | `GH_TOKEN_FOR_ART_GALLERY_RELEASE_TOOLS` | `art-gallery-release-tools` の `workflow_dispatch` を呼び出せる PAT |
