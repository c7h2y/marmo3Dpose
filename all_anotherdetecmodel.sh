#!/bin/bash
source /home/administrator/anaconda3/etc/profile.d/conda.sh

device_str="cuda:0"
config_path='./calib/marmo_cj425m/config.yaml'
raw_data_dir='../vid'

label2d_dir='./results/2d_v0p8_Dark_fix_20_all_det'
vid2dout_dir='./results/video/2d_v0p8_dark_fix_20_all_det'
results3d_dir="./results/3d_v0p8_dark_fix_20_all_det"
vidout_dir='./results/video/3d_v0p8_dark_fix_20_all_det'
label2d_output_dir='./results/2d_v0p8_Dark_fix_20_all_det'
viddir='./results/video'

calib_3d_toml='./calibration_tmpl.toml'
config_3d_toml='./config_tmpl.toml'

mkdir $viddir
mkdir $label2d_dir
mkdir $results3d_dir
mkdir $vid2dout_dir
mkdir $vidout_dir

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

# 2D Proc
flgDo=0

sessions=() 
sessions_raw=()

raw_data_dir="${1:-/path/to/raw}"  # you can also hard-code or export this
splits_count="${2:-2}"             # number of chunks (N)
split_id="${3:-1}"                 # which chunk to pick (1…N)
shift 3                            # if you want to pass more args to process_sessions.sh

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
#    each chunk has at most ceil(total/N) entries.
chunk_size=$(( (total + splits_count - 1) / splits_count ))
start=$(( (split_id - 1) * chunk_size ))
selected=( "${sessions[@]:start:chunk_size}" )

# --- OR, 2b) ROUND-ROBIN-BY-INDEX method: ---
# selected=()
# for idx in "${!sessions[@]}"; do
#   # distribute indices 0…total-1 into N groups by modulo
#   (( (idx % splits_count) + 1 == split_id )) && \
#     selected+=( "${sessions[idx]}" )
# done

# 3) do something with the selected sessions
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
        # raw_data_dir=${raw_data_dirs[$sescnt]}
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
