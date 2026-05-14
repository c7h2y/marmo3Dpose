#!/bin/bash
# Parallel 2D + 3D pose estimation — processes one chunk of sessions.
# Run from within the marmo3Dpose directory with venv activated:
#   source /path/to/venv/bin/activate
#   bash allmulti.sh <raw_data_dir> <num_chunks> <chunk_id> [cuda_device]
#
# Example (chunk 1 of 4 on GPU 0):
#   bash allmulti.sh /path/to/vid 4 1 0

set -euo pipefail

raw_data_dir="${1:-../vid}"   # directory containing session folders
splits_count="${2:-1}"        # total number of parallel jobs
split_id="${3:-1}"            # which chunk this job handles (1-indexed)
cuda="${4:-0}"

export CUDA_VISIBLE_DEVICES="$cuda"
echo "CUDA_VISIBLE_DEVICES=$cuda  chunk $split_id/$splits_count"

# ---------------------------------------------------------------------------
# Paths — edit these to match your environment
# ---------------------------------------------------------------------------
device_str="cuda:0"
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

# Collect unique session names
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

total=${#sessions[@]}
if (( total == 0 )); then
    echo "No sessions found in '$raw_data_dir'" >&2
    exit 1
fi
if (( split_id < 1 || split_id > splits_count )); then
    echo "split_id ($split_id) must be between 1 and $splits_count" >&2
    exit 1
fi

# Assign sessions to this chunk (contiguous)
chunk_size=$(( (total + splits_count - 1) / splits_count ))
start=$(( (split_id - 1) * chunk_size ))
selected=( "${sessions[@]:start:chunk_size}" )

if (( ${#selected[@]} == 0 )); then
    echo "No sessions in chunk $split_id/$splits_count" >&2
    exit 1
fi

echo "Processing ${#selected[@]} sessions (chunk $split_id/$splits_count):"
printf '  - %s\n' "${selected[@]}"

for session in "${selected[@]}"; do
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
