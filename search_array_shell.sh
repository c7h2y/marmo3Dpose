#!/usr/bin/env bash

# 使い方:
#   ./missing_kp3d_dirs.sh            # カレントディレクトリ直下のサブフォルダを見る
#   ./missing_kp3d_dirs.sh /path/to/dir

TARGET_DIR="${1:-.}"

shopt -s nullglob
subdirs=("$TARGET_DIR"/*/)
shopt -u nullglob

missing_dirs=()

for d in "${subdirs[@]}"; do
    # 末尾のスラッシュを削る
    dir_no_slash="${d%/}"

    # そのサブフォルダ以下に kp3d*.pickle があるかどうか
    if find "$dir_no_slash" -type f -name 'kp3d*.pickle' -print -quit | grep -q .; then
        :  # あれば何もしない
    else
        missing_dirs+=("$dir_no_slash")
    fi
done

# 配列形式で出力（Bash で安全に読めるようにエスケープ）
if ((${#missing_dirs[@]} > 0)); then
    printf 'missing_dirs=('
    for dir in "${missing_dirs[@]}"; do
        printf ' %q' "$dir"
    done
    printf ' )\n'
else
    echo 'missing_dirs=()'
fi
