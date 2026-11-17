#!/usr/bin/env bash
# Build do Flutter Web para a Vercel. Saída publicada: build/web
set -euo pipefail

FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"
# Opcional: fixe uma versão (ex.: FLUTTER_VERSION=3.27.4) nas variáveis da Vercel.
FLUTTER_REF="${FLUTTER_VERSION:-$FLUTTER_CHANNEL}"
FLUTTER_DIR="${FLUTTER_DIR:-$HOME/flutter-sdk}"

cd "$(dirname "$0")/.."

echo "==> Verificando variáveis de ambiente"
missing=0
for var in SUPABASE_URL SUPABASE_PUBLISHABLE_KEY; do
  if [ -z "${!var:-}" ]; then
    echo "ERRO: variável $var não definida (Vercel > Settings > Environment Variables)." >&2
    missing=1
  fi
done
[ "$missing" -eq 0 ] || exit 1

echo "==> Instalando Flutter ($FLUTTER_REF)"
if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  git clone --depth 1 --branch "$FLUTTER_REF" \
    https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"
export FLUTTER_SUPPRESS_ANALYTICS=true
export CI=true

flutter config --no-analytics >/dev/null 2>&1 || true
flutter config --enable-web
flutter --version

# O repositório não versiona as pastas de plataforma; gera a de web se faltar.
if [ ! -d web ]; then
  echo "==> Pasta web/ ausente: executando flutter create (somente web)"
  flutter create . --platforms web --project-name agile_knowledge
fi

echo "==> flutter pub get"
flutter pub get

DEFINES=(
  "--dart-define=SUPABASE_URL=${SUPABASE_URL}"
  "--dart-define=SUPABASE_PUBLISHABLE_KEY=${SUPABASE_PUBLISHABLE_KEY}"
)
if [ -n "${EMAIL_CONFIRMATION_REDIRECT_URL:-}" ]; then
  DEFINES+=("--dart-define=EMAIL_CONFIRMATION_REDIRECT_URL=${EMAIL_CONFIRMATION_REDIRECT_URL}")
fi

echo "==> flutter build web --release"
flutter build web --release "${DEFINES[@]}"

test -f build/web/index.html || { echo "ERRO: build/web/index.html não foi gerado." >&2; exit 1; }
echo "==> Build concluído: build/web"
