#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
marmo3dpose_fix_20.py
- bash 版 marmo3dpose_fix_20.sh を Python に移植
- conda 環境は `conda run -n <env> python ...` で実行
"""

from __future__ import annotations
import argparse
import os
import sys
import subprocess
from pathlib import Path
from typing import List

# ---------- ユーティリティ ----------

PROJ_ROOT = Path(__file__).resolve().parent.parent  # scripts/.. = repo root


def shlex_join(parts: List[str]) -> str:
    """表示用。subprocess には配列で渡すので未使用でもOK"""
    import shlex
    return " ".join(shlex.quote(p) for p in parts)


def run(cmd: List[str], cwd: Path | None = None) -> None:
    """サブプロセス実行（失敗で例外）"""
    print(f"[RUN] {shlex_join(cmd)}")
    subprocess.run(cmd, cwd=str(cwd or PROJ_ROOT), check=True)


def conda_python(env: str) -> List[str]:
    """conda の python 実行プレフィクス（conda が PATH 上にあること）"""
    return ["conda", "run", "-n", env, "python"]


def ensure_dirs(paths: List[Path]) -> None:
    for p in paths:
        p.mkdir(parents=True, exist_ok=True)


# ---------- 元スクリプトのデフォルト値 ----------

DEFAULTS = dict(
    device_str="cuda:0",
    config_path="data/calib/marmo_cj425m/config.yaml",
    raw_data_dir="data",
    label2d_dir="results/2d_v0p8_Dark_fix_20",
    results3d_dir="results/3d_v0p8_dark_fix_20",
    vid2dout_dir="results/video/2d_v0p8_dark_fix_20",
    vidout_dir="results/video/3d_v0p8_dark_fix_20",
    calib_3d_toml="configs/calibration_tmpl.toml",
    config_3d_toml="configs/config_tmpl.toml",
    pose_config="models/pose/marmo20/marmo20_tk_hrnet_w48_coco_384x288_dark_v0p10_IDgeneralization.py",
    pose_checkpoint="weight/marmo20_pose.pth",
    tracking_config="models/track/marmo20/tk_bytetrack_yolox_v0p8.py",
    id_config="models/id/tk_resnet50_8xb32_in1k.py",
    id_checkpoint="weight/id.pth",
    fps=24,
    t_invt="None",
    n_kp=20,
    thr_kp_detection=0.5,
    procFrame=100,
)

DAYS_DEFAULT = [
    "20230826", "20230722", "20230701", "20230527", "20230429",
    "20230325", "20230311", "20230225", "20230218", "20230211",
    "20230827", "20230723", "20230702", "20230528", "20230430",
    "20230326", "20230312", "20230226", "20230219", "20230212",
]

HOURS_DEFAULT = ["100000", "120000", "140000", "160000", "090000", "110000", "130000", "150000"]


def sessions_from_batch(batch_id: int) -> tuple[List[str], List[str], str]:
    """
    bash の条件分岐を Python で再現し、(days, hours, device_str) を返す
    """
    days = DAYS_DEFAULT[:]
    hours = HOURS_DEFAULT[:]
    device_str = "cuda:0"

    if batch_id == 1:
        device_str = "cuda:0"  # yagido
        days = ["20231230", "20231126", "20231001", "20230722", "20230701", "20230311", "20230225", "20230218", "20230211"]
    elif batch_id == 2:
        device_str = "cuda:0"  # yagido
        days = ["20230226"]
    elif batch_id == 3:
        device_str = "cuda:1"  # hinai
        days = ["20240225", "20240127", "20231029", "20230826", "20230527", "20230429", "20230325"]
    elif batch_id == 4:
        device_str = "cuda:0"  # hinai-
        days = ["20240224", "20240128", "20231028", "20230827", "20230528", "20230430", "20230326"]
    elif batch_id == 5:
        device_str = "cuda:0"  # hinai-
        days = ["20250202"]
        hours = ["080000", "090000", "100000", "110000", "120000", "130000", "140000", "150000", "160000", "170000", "180000"]
    elif batch_id == 6:
        device_str = "cuda:0"  # hinai-
        days = ["20250201"]
        hours = ["160000", "170000", "180000"]
    elif batch_id == 7:
        device_str = "cuda:0"
        days = ["20230226"]
        hours = ["110000"]

    return days, hours, device_str


def build_sessions(days: List[str], hours: List[str]) -> List[str]:
    sessions: List[str] = []
    for day in days:
        for hour in hours:
            sessions.append(f"dailylife_cj611_{day}_{hour}")
    return sessions


# ---------- メイン処理 ----------

def main() -> None:
    ap = argparse.ArgumentParser(description="Run 2D/3D pipelines via Python (conda run)")
    ap.add_argument("--batch", type=int, default=1, help="batchID (1..7)")
    ap.add_argument("--dry-run", action="store_true", help="コマンド実行せず表示のみ")
    ap.add_argument("--only-2d", action="store_true", help="2D のみ実行（デフォルトは2D; 3D部分はコメントアウト）")
    ap.add_argument("--openmmlab-env", default="openmmlab2")
    ap.add_argument("--multicam-env", default="multicam2")
    args = ap.parse_args()

    # 設定
    cfg = DEFAULTS.copy()
    days, hours, device_from_batch = sessions_from_batch(args.batch)
    sessions = build_sessions(days, hours)

    # batch 指定に伴う device 反映（必要に応じて）
    cfg["device_str"] = device_from_batch or cfg["device_str"]

    # ディレクトリ作成
    label2d_dir = PROJ_ROOT / cfg["label2d_dir"]
    results3d_dir = PROJ_ROOT / cfg["results3d_dir"]
    vid2dout_dir = PROJ_ROOT / cfg["vid2dout_dir"]
    vidout_dir = PROJ_ROOT / cfg["vidout_dir"]
    ensure_dirs([label2d_dir, results3d_dir, vid2dout_dir, vidout_dir])

    # 表示
    print(f"[INFO] repo root     : {PROJ_ROOT}")
    print(f"[INFO] batch         : {args.batch}")
    print(f"[INFO] sessions      : {len(sessions)} items")
    print(f"[INFO] device_str    : {cfg['device_str']}")

    # 2D 処理
    for i, session in enumerate(sessions, 1):
        print(f"\n=== ({i}/{len(sessions)}) 2D: {session} ===")
        cmd = (
            conda_python(args.openmmlab_env)
            + [
                str(PROJ_ROOT / "src" / "process_2d.py"),
                "--config_path", cfg["config_path"],
                "--data_name", session,
                "--raw_data_dir", cfg["raw_data_dir"],
                "--label2d_dir", cfg["label2d_dir"],
                "--device_str", cfg["device_str"],
                "--tracking_config", cfg["tracking_config"],
                "--pose_config", cfg["pose_config"],
                "--pose_checkpoint", cfg["pose_checkpoint"],
                "--id_config", cfg["id_config"],
                "--id_checkpoint", cfg["id_checkpoint"],
                "--procFrame", str(cfg["procFrame"]),
            ]
        )
        if args.dry_run:
            print("[DRY] " + shlex_join(cmd))
        else:
            run(cmd)

        # --- 2D可視化（必要ならコメント解除）
        # for cam in ["23506214","23506226","23506236","23506237","23506239","23511607","23511613","23511614"]:
        #     vcmd = (
        #         conda_python(args.openmmlab_env)
        #         + [
        #             str(PROJ_ROOT / "visualize_2D.py"),
        #             "--path_vid", f"{cfg['raw_data_dir']}/{session}.{cam}/000000.mp4",
        #             "--path_json", f"{cfg['label2d_dir']}/{session}/{session}_{cam}_000000.json",
        #             "--path_output", f"{cfg['vid2dout_dir']}/{session}_{cam}_000000.mp4",
        #             "--n_frame_to_save", "11000",
        #         ]
        #     )
        #     if args.dry_run:
        #         print("[DRY] " + shlex_join(vcmd))
        #     else:
        #         run(vcmd)

        # --- 3D（元スクリプトはコメントアウト。必要なら解放して使用）
        # print(f"--- 3D Proc: {session} ---")
        # t_intv = cfg["t_invt"]
        # pcmd = (
        #     conda_python(args.multicam_env)
        #     + [
        #         str(PROJ_ROOT / "process_3d.py"),
        #         "--config_3d_toml", cfg["config_3d_toml"],
        #         "--calib_3d_toml", cfg["calib_3d_toml"],
        #         "--config_path", cfg["config_path"],
        #         "--fps", str(cfg["fps"]),
        #         "--t_intv", str(t_intv),
        #         "--n_kp", str(cfg["n_kp"]),
        #         "--thr_kp_detection", str(cfg["thr_kp_detection"]),
        #         "--results3d_dir", cfg["results3d_dir"],
        #         "--raw_data_dir", cfg["raw_data_dir"],
        #         "--label2d_dir", cfg["label2d_dir"],
        #         "--data_name", session,
        #     ]
        # )
        # if args.dry_run:
        #     print("[DRY] " + shlex_join(pcmd))
        # else:
        #     run(pcmd)
        #
        # print(f"--- 3D Vis: {session} ---")
        # i_cam = 6
        # n_frame2draw = 11000
        # pickle_dir = f"{cfg['results3d_dir']}/{session}"
        # v3cmd = (
        #     conda_python(args.multicam_env)
        #     + [
        #         str(PROJ_ROOT / "visualize_3D.py"),
        #         "--config_path", cfg["config_path"],
        #         "--data_name", session,
        #         "--raw_data_dir", cfg["raw_data_dir"],
        #         "--pickledata_dir", pickle_dir,
        #         "--vidout_dir", cfg["vidout_dir"],
        #         "--i_cam", str(i_cam),
        #         "--n_frame2draw", str(n_frame2draw),
        #     ]
        # )
        # if args.dry_run:
        #     print("[DRY] " + shlex_join(v3cmd))
        # else:
        #     run(v3cmd)

    print("\n[ALL DONE]")


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as e:
        sys.stderr.write(f"\n[ERROR] command failed with code {e.returncode}\n")
        sys.exit(e.returncode)
