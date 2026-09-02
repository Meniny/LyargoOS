#!/usr/bin/env bash
SCRIPT_PATH="$(realpath "$0")"
SCRIPT_FOLDER="$(cd "$(dirname "$SCRIPT_PATH")" && readlink -f "$(pwd)")"
exec "$SCRIPT_FOLDER/mkiso.sh" -m "https://mirrors.tuna.tsinghua.edu.cn/voidlinux/current"
