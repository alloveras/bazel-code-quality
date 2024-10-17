#!/usr/bin/env bash

set -eu -o pipefail

LOCAL_BIN_DIR="${HOME}/.local/bin"

if ! command -v chezmoi >/dev/null 2>&1; then
    echo "👊  Installing chezmoi ..."
    bash -c "$(curl -fsLS get.chezmoi.io)" -- -b "${LOCAL_BIN_DIR}"
fi

echo ""
echo "🚀  Initializing dotfiles ..."
chezmoi init --apply "https://github.com/alloveras/dotfiles" --promptString "email=albert.l@canva.com"
