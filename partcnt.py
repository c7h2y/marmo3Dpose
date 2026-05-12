import os
import re
import subprocess
import sys

# --- 設定 ---
ROOT_DIR = "../single"
VIDEO_EXTS = {".mp4", ".mov", ".avi", ".mkv", ".flv", ".wmv"}

# フォルダ名から「dailylife_cj<番号>_…」を抽出
DIR_PATTERN = re.compile(r"^dailylife_cj(\d+)_", re.IGNORECASE)

def get_frame_count(path):
    cmd = [
        "ffprobe", "-v", "error",
        "-select_streams", "v:0",
        "-count_frames",
        "-show_entries", "stream=nb_read_frames",
        "-of", "default=nokey=1:noprint_wrappers=1",
        path
    ]
    try:
        out = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
        return int(out.strip())
    except Exception as e:
        # エラーは None を返して無視
        return None

def main():
    # ID → 合計フレーム数
    id_to_total = {}

    # 各サブフォルダを走査
    for entry in os.scandir(ROOT_DIR):
        if not entry.is_dir():
            continue
        m = DIR_PATTERN.match(entry.name)
        if not m:
            continue

        vid_id = m.group(1)
        subtotal = 0

        # フォルダ内の動画をすべて走査して合計
        for dirpath, _, filenames in os.walk(entry.path):
            for fn in filenames:
                if os.path.splitext(fn)[1].lower() not in VIDEO_EXTS:
                    continue
                fullpath = os.path.join(dirpath, fn)
                cnt = get_frame_count(fullpath)
                if cnt is not None:
                    subtotal += cnt
                # ↓詳細出力を無効化
                # else:
                #     print(f"  ✗ {fullpath} → 取得失敗")
        id_to_total[vid_id] = subtotal

    if not id_to_total:
        print("該当するフォルダが見つかりませんでした。")
        sys.exit(1)

    # ─────────────
    # ここだけ出力
    # ─────────────
    print("=== 個体ごとの合計フレーム数 ===")
    for vid_id in sorted(id_to_total.keys(), key=lambda x: int(x)):
        total = id_to_total[vid_id]
        print(f"cj{vid_id} → {total} フレーム")

if __name__ == "__main__":
    main()
