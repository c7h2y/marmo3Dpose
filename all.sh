#!/bin/bash
# Single-process 2D + 3D pose estimation pipeline.
# Run from within the marmo3Dpose directory with venv activated:
#   source /path/to/venv/bin/activate
#   bash all.sh

set -euo pipefail

# ---------------------------------------------------------------------------
# Paths — edit these to match your environment
# ---------------------------------------------------------------------------
device_str="cuda:0"
raw_data_dir='../vid'                        # directory containing session folders
config_path='./calib/marmo_cj425m/config.yaml'

label2d_dir='./results/2d_v0p8_Dark_fix_20_all'
results3d_dir='./results/3d_v0p8_dark_fix_20_all'
vidout_dir='./results/video/3d_v0p8_dark_fix_20_all'
vid2dout_dir='./results/video/2d_v0p8_dark_fix_20_all'
viddir='./results/video'

calib_3d_toml='./calibration_tmpl.toml'
config_3d_toml='./config_tmpl.toml'

pose_config='model/pose/marmo20/marmo20_tk_hrnet_w48_coco_384x288_dark_v0p10_IDgeneralization.py'
pose_checkpoint='weight/marmo20_pose.pth'   # download from Zenodo
tracking_config='model/track/marmo20/tk_bytetrack_yolox_v0p8.py'
id_config='model/id/tk_resnet50_8xb32_in1k.py'
id_checkpoint='weight/id.pth'               # download from Zenodo
# ---------------------------------------------------------------------------

fps=24
n_kp=20
thr_kp_detection=0.5
procFrame=-1  # -1 = all frames

mkdir -p "$viddir" "$label2d_dir" "$results3d_dir" "$vid2dout_dir" "$vidout_dir"

# Collect unique session names from raw_data_dir
sessions=()
declare -A seen
for dir in "$raw_data_dir"/*/; do
    [[ -d "$dir" ]] || continue
    base=$(basename "$dir")
    base="${base%%.*}"
    if [[ -z "${seen[$base]:-}" ]]; then
        seen[$base]=1
        sessions+=("$base")
    fi
done

if (( ${#sessions[@]} == 0 )); then
    echo "No sessions found in '$raw_data_dir'" >&2
    exit 1
fi

printf '%s\n' "${sessions[@]}"

for session in "${sessions[@]}"; do
    echo "=== $session ==="
    data_name="$session"

    # 2D estimation
    python ./process_2d.py \
        --config_path ${config_path} \
        --data_name ${data_name} \
        --raw_data_dir ${raw_data_dir} \
        --label2d_dir ${label2d_dir} \
        --device_str ${device_str} \
        --tracking_config ${tracking_config} \
        --pose_config ${pose_config} \
        --pose_checkpoint ${pose_checkpoint} \
        --id_config ${id_config} \
        --id_checkpoint ${id_checkpoint} \
        --procFrame ${procFrame}

    # 3D reconstruction
    python ./process_3d.py \
        --config_3d_toml ${config_3d_toml} \
        --calib_3d_toml ${calib_3d_toml} \
        --config_path ${config_path} \
        --fps ${fps} \
        --t_intv None \
        --n_kp ${n_kp} \
        --thr_kp_detection ${thr_kp_detection} \
        --results3d_dir ${results3d_dir} \
        --raw_data_dir ${raw_data_dir} \
        --label2d_dir ${label2d_dir} \
        --data_name ${data_name}

    # Visualization
    python ./visualize_3D.py \
        --config_path ${config_path} \
        --data_name ${data_name} \
        --raw_data_dir ${raw_data_dir} \
        --pickledata_dir ${results3d_dir}/${data_name} \
        --vidout_dir ${vidout_dir} \
        --i_cam 6 \
        --n_frame2draw 10000
done
