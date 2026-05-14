#!/bin/bash
# 使い方: ./all_anotherdetecmodel.sh [raw_data_dir] [splits_count] [split_id] [config_path] [results_base]
CONDA_SH="${CONDA_SH:-/home/administrator/anaconda3/etc/profile.d/conda.sh}"
source "$CONDA_SH"

raw_data_dir="${1:-../vid}"
splits_count="${2:-2}"
split_id="${3:-1}"
config_path="${4:-./calib/marmo_cj425m/config.yaml}"
results_base="${5:-./results}"

device_str="cuda:0"

label2d_dir="${results_base}/2d_v0p8_Dark_fix_20_all_det"
vid2dout_dir="${results_base}/video/2d_v0p8_dark_fix_20_all_det"
results3d_dir="${results_base}/3d_v0p8_dark_fix_20_all_det"
vidout_dir="${results_base}/video/3d_v0p8_dark_fix_20_all_det"
label2d_output_dir="${results_base}/2d_v0p8_Dark_fix_20_all_det"
viddir="${results_base}/video"

calib_3d_toml='./calibration_tmpl.toml'
config_3d_toml='./config_tmpl.toml'

mkdir -p $viddir
mkdir -p $label2d_dir
mkdir -p $results3d_dir
mkdir -p $vid2dout_dir
mkdir -p $vidout_dir

pose_config='model/pose/marmo20/marmo20_tk_hrnet_w48_coco_384x288_dark_v0p10_IDgeneralization.py'
pose_checkpoint='weight/marmo20_pose.pth'

tracking_config='model/track/marmo20/tk_bytetrack_yolox_v0p8_marmo20.py'
id_config='model/id/tk_resnet50_8xb32_in1k.py'
id_checkpoint='weight/id.pth'

fps=24
t_invt="None"
n_kp=20
thr_kp_detection=0.5

# procFrame=1000
procFrame=-1

# 1) Collect and dedupe session names
sessions_raw=()
for dir in "$raw_data_dir"/*; do
  [[ -d "$dir" ]] || continue
  sessions_raw+=( "$(basename "$dir")" )
done

declare -A seen=()
sessions=()
for f in "${sessions_raw[@]}"; do
  base="${f%%.*}"
  if [[ -z "${seen[$base]:-}" ]]; then
    seen[$base]=1
    sessions+=( "$base" )
  fi
done

total=${#sessions[@]}
if (( total == 0 )); then
  echo "⚠️  No sessions found in '$raw_data_dir'" >&2
  exit 1
fi
if (( split_id < 1 || split_id > splits_count )); then
  echo "⚠️  split_id ($split_id) must be between 1 and $splits_count" >&2
  exit 1
fi

# 2a) CONTIGUOUS-CHUNK method:
chunk_size=$(( (total + splits_count - 1) / splits_count ))
start=$(( (split_id - 1) * chunk_size ))
selected=( "${sessions[@]:start:chunk_size}" )

if (( ${#selected[@]} == 0 )); then
  echo "⚠️  No sessions in chunk $split_id of $splits_count" >&2
  exit 1
fi

echo "▶ Processing ${#selected[@]} sessions (chunk $split_id/$splits_count):"
printf '  - %s\n' "${selected[@]}"

camNames=("23506214" "23506226" "23506236" "23506237" "23506239" "23511607" "23511613" "23511614")

sescnt=-1
for session in ${selected[@]};do
        printf "\n%s\n", $session
        sescnt=`expr $sescnt + 1`
        echo $raw_data_dir
        data_name=$session
        conda activate openmmlab2

        export CUDA_VISIBLE_DEVICES=1

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
        flg=0

        # for camName in ${camNames[@]};do
        #         python ./visualize_2D.py  \
        #                 --path_vid ${raw_data_dir}/${data_name}.${camName}/000000.mp4  \
        #                 --path_json ${label2d_output_dir}/${data_name}/${data_name}_${camName}_000000.json \
        #                 --path_output ${vid2dout_dir}/${data_name}_${camName}_000000.mp4 \
        #                 --n_frame_to_save 11000
        # done

        # 3D Proc
        t_intv='None'
        conda activate multicam2
        python ./process_3d.py \
                 --config_3d_toml ${config_3d_toml}\
                 --calib_3d_toml ${calib_3d_toml}\
                 --config_path ${config_path}\
                 --fps ${fps}\
                 --t_intv ${t_intv}\
                 --n_kp ${n_kp} \
                 --thr_kp_detection ${thr_kp_detection}\
                 --results3d_dir ${results3d_dir} \
                 --raw_data_dir ${raw_data_dir}\
                 --label2d_dir ${label2d_dir}\
                 --data_name ${data_name}

        i_cam=6
        n_frame2draw=10000
        pickledata_dir=${results3d_dir}'/'$data_name
        python ./visualize_3D.py \
                --config_path ${config_path}\
                --data_name ${data_name} \
                --raw_data_dir ${raw_data_dir}\
                --pickledata_dir ${pickledata_dir}\
                --vidout_dir ${vidout_dir} \
                --i_cam ${i_cam}\
                --n_frame2draw ${n_frame2draw}
done
