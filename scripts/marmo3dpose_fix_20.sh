#!/usr/bin/env bash
set -euo pipefail

# --- どこから実行してもプロジェクトルートを解決 ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJ_ROOT"

# --- conda の読み込み（存在チェック付き）---
if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
  source "$HOME/miniconda3/etc/profile.d/conda.sh"
elif [ -f "/opt/conda/etc/profile.d/conda.sh" ]; then
  source "/opt/conda/etc/profile.d/conda.sh"
else
  echo "conda.sh が見つかりませんでした" >&2
  exit 1
fi

batchID=${1:-1}
device_str="cuda:0"

config_path='calib/marmo_cj425m/config.yaml'
raw_data_dir='vid'

label2d_dir='results/2d_v0p8_Dark_fix_20'
vid2dout_dir='results/video/2d_v0p8_dark_fix_20'
results3d_dir='results/3d_v0p8_dark_fix_20'
vidout_dir='results/video/3d_v0p8_dark_fix_20'
label2d_output_dir='results/2d_v0p8_Dark_fix_20'

calib_3d_toml='calibration_tmpl.toml'
config_3d_toml='config_tmpl.toml'

# 出力系ディレクトリは -p を付けて安全に
mkdir -p "$label2d_dir" "$results3d_dir" "$vid2dout_dir" "$vidout_dir"

pose_config='model/pose/marmo20/marmo20_tk_hrnet_w48_coco_384x288_dark_v0p10_IDgeneralization.py'
pose_checkpoint='weight/marmo20_pose.pth'
tracking_config='model/track/marmo20/tk_bytetrack_yolox_v0p8.py'
id_config='model/id/tk_resnet50_8xb32_in1k.py'
id_checkpoint='weight/id.pth'

fps=24
t_invt="None"
n_kp=20
thr_kp_detection=0.5
procFrame=-1

# 2D Proc
flgDo=1

if [ ${batchID} -eq 1 ]; then 
        device_str="cuda:0"
fi 
if [ ${batchID} -eq 2 ]; then 
        device_str="cuda:0"
fi 
if [ ${batchID} -eq 3 ]; then 
        device_str="cuda:0"
fi 
if [ ${batchID} -eq 4 ]; then 
        device_str="cuda:0"
fi 
if [ ${batchID} -eq 5 ]; then 
        device_str="cuda:0"
fi 
if [ ${batchID} -eq 6 ]; then 
        device_str="cuda:0"
fi 

if [ ${batchID} -eq 7 ]; then 
        device_str="cuda:0"
fi 

sessions=() 
# raw_data_dir=()
days=(
      '20230826' '20230722' '20230701' '20230527' '20230429' '20230325' '20230311' '20230225' '20230218' '20230211' 
      '20230827' '20230723' '20230702' '20230528' '20230430' '20230326' '20230312' '20230226' '20230219' '20230212'             
      )
hours=( '100000' '120000' '140000' '160000'
        '090000' '110000' '130000' '150000')
if [ ${batchID} -eq 1 ]; then 
        device_str="cuda:0" # yagido 
        days=('20231230' '20231126' '20231001' '20230722' '20230701' '20230311' '20230225' '20230218' '20230211')
fi 
if [ ${batchID} -eq 2 ]; then 
        device_str="cuda:0" # yagido 
        days=('20230226')
fi 
if [ ${batchID} -eq 3 ]; then 
        device_str="cuda:1" # hinai
        days=('20240225' '20240127' '20231029' '20230826' '20230527' '20230429' '20230325' )
fi 
if [ ${batchID} -eq 4 ]; then 
        device_str="cuda:0" # hinai-
        days=('20240224' '20240128' '20231028' '20230827' '20230528' '20230430' '20230326'  )
fi 
if [ ${batchID} -eq 5 ]; then 
        device_str="cuda:0" # hinai-
        days=('20250202')
        hours=('080000' '090000' '100000' '110000' '120000' '130000',
               '140000' '150000' '160000' '170000' '180000')
fi 
if [ ${batchID} -eq 6 ]; then 
        device_str="cuda:0" # hinai-
        days=('20250201')
        hours=('160000' '170000' '180000')
fi 

if [ ${batchID} -eq 7 ]; then 
        device_str="cuda:0" # hinai-
        days=('20220514' '20220611' '20220806' '20220903' '20221015' '20221106')
        hours=('130000' '150000' '090000' '110000' '100000')
fi 

if [ ${batchID} -eq 7 ]; then 
        device_str="cuda:0" # hinai-
        days=('20230226')
        hours=('110000')
fi 

## 個体番号を適宜変える
for day in ${days[@]}; do
    for hour in ${hours[@]}; do
        echo ${day}_${hour}
        session='dailylife_cj611_'${day}'_'${hour}
        raw_data_dirs+=('')
        sessions+=($session)
    done
done


# for day in ${days[@]};do 
#         for hour in ${hours[@]};do 
#                 echo ${day}_${hour}
#                 session='dailylife_cj611_'${day}'_'${hour}
#                 raw_data_dirs+=('')
#                 sessions+=($session)
#         done
# done 

for session in ${sessions[@]};do
        echo $session
done 

camNames=("23506214" "23506226" "23506236" "23506237" "23506239" "23511607" "23511613" "23511614")

sescnt=-1
for session in ${sessions[@]};do
        sescnt=`expr $sescnt + 1`
        data_name=$session
        conda activate openmmlab2

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

        for camName in ${camNames[@]};do
                python ./visualize_2D.py  \
                        --path_vid ${raw_data_dir}/${data_name}.${camName}/000000.mp4  \
                        --path_json ${label2d_output_dir}/${data_name}/${data_name}_${camName}_000000.json \
                        --path_output ${vid2dout_dir}/${data_name}_${camName}_000000.mp4 \
                        --n_frame_to_save 11000
        done

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
        n_frame2draw=11000
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
