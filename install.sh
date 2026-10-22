#!/usr/bin/env bash
# redisX installer (macOS/Linux) — builds redisX from source and installs
# standalone binaries. Requires a working Rust toolchain (cargo) already
# installed on this machine: https://rustup.rs
#
# Usage:
#   ./install.sh              # build + install to /usr/local/bin/redisX
#   INSTALL_DIR=... ./install.sh
#   ./install.sh --force      # wipe INSTALL_DIR first, then install
#   ./install.sh --clean      # --force + cargo clean (full rebuild)
set -euo pipefail

FORCE=0
CLEAN=0
for arg in "$@"; do
    case "$arg" in
        --force) FORCE=1 ;;
        --clean) FORCE=1; CLEAN=1 ;;
        *)
            echo "Usage: $0 [--force] [--clean]" >&2
            exit 1
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin/redisX}"

if [ "$FORCE" -eq 1 ]; then
    echo "==> --force: confirming sudo access before touching $INSTALL_DIR ..."
    sudo -v
    if [ -e "$INSTALL_DIR" ]; then
        echo "==> Removing existing $INSTALL_DIR ..."
        sudo rm -rf "$INSTALL_DIR"
    fi
fi

if [ "$CLEAN" -eq 1 ]; then
    echo "==> --clean: running cargo clean before rebuilding from scratch ..."
    cargo clean
fi

echo "==> Building release binaries (cargo build --release --workspace --features redisx-server/python,redisx-server/polars)..."
if ! cargo build --release --workspace --features redisx-server/python,redisx-server/polars; then
    echo "" >&2
    echo "==================================================================" >&2
    echo "오류: 빌드에 실패했습니다." >&2
    echo "redisX는 소스에서 직접 빌드되며, 이 컴퓨터에 Rust(cargo)가" >&2
    echo "설치되어 있지 않아서 발생한 오류일 가능성이 높습니다." >&2
    echo "https://rustup.rs 에서 Rust를 설치한 뒤 터미널을 새로 열고" >&2
    echo "다시 실행해주세요." >&2
    echo "==================================================================" >&2
    exit 1
fi

maybe_sudo_mkdir() {
    if [ -d "$INSTALL_DIR" ] && [ -w "$INSTALL_DIR" ]; then
        return
    fi
    if mkdir -p "$INSTALL_DIR" 2>/dev/null && [ -w "$INSTALL_DIR" ]; then
        return
    fi
    echo "==> $INSTALL_DIR isn't writable without sudo; asking for it now..."
    sudo mkdir -p "$INSTALL_DIR"
    sudo chown "$(id -u):$(id -g)" "$INSTALL_DIR"
}

install_one() {
    local src="$1" dst="$INSTALL_DIR/$2"
    if [ -w "$INSTALL_DIR" ]; then
        cp "$src" "$dst"
    else
        sudo cp "$src" "$dst"
    fi
}

echo "==> Installing to $INSTALL_DIR ..."
maybe_sudo_mkdir
install_one target/release/redisx-server redisx-server
install_one target/release/redisx-cli redisx-cli
install_one target/release/redisx-benchmark redisx-benchmark

cat <<EOF

==================================================================
redisX installed to: $INSTALL_DIR
  redisx-server, redisx-cli, redisx-benchmark

[1] 설정 파일(redisx.conf)은 redisx-server를 처음 실행할 때
    $INSTALL_DIR 안에 기본값으로 자동 생성됩니다.
    세부 설정(포트, 메모리 제한 등)을 바꾸려면 다음 파일을 수정한 뒤
    서버를 재시작하세요:
      $INSTALL_DIR/redisx.conf

[2] cargo나 전체 경로 없이 어디서든 redisx-server / redisx-cli를
    실행하려면, 아래 한 줄을 ~/.zshrc (zsh 사용 시) 또는 ~/.shrc
    (sh/bash 사용 시)에 추가한 뒤 터미널을 새로 열거나
    'source ~/.zshrc' 등을 실행하세요:

      export PATH="$INSTALL_DIR:\$PATH"
==================================================================
EOF
