#!/bin/bash
# 使い方: ./all.sh [raw_data_dir] [config_path] [results_base] [device_str]

raw_data_dir="${1:-../vid}"
config_path="${2:-./calib/marmo_cj425m/config.yaml}"
results_base="${3:-./results}"
device_str="${4:-cuda:0}"

label2d_dir="${results_base}/2d_v0p8_Dark_fix_20_all"
vid2dout_dir="${results_base}/video/2d_v0p8_dark_fix_20_all"
results3d_dir="${results_base}/3d_v0p8_dark_fix_20_all"
vidout_dir="${results_base}/video/3d_v0p8_dark_fix_20_all"
label2d_output_dir="${results_base}/2d_v0p8_Dark_fix_20_all"
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

tracking_config='model/track/marmo20/tk_bytetrack_yolox_v0p8.py'
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

for dir in "$raw_data_dir"/*; do
    if [ -d "$dir" ]; then
        session=$(basename "$dir")
        sessions_raw+=("$session")
    fi
done

declare -A seen

for f in "${sessions_raw[@]}"; do
    base=${f%%.*}

    if [[ -z "${seen[$base]}" ]]; then
        seen[$base]=1
        sessions+=("$base")
    fi
done

printf '%s\n' "${sessions[@]}"

#exit 1
### 個体番号を適宜変える
#for day in ${days[@]}; do
#    for hour in ${hours[@]}; do
#        echo ${day}_${hour}
#        session='dailylife_cj611_'${day}'_'${hour}
#        raw_data_dirs+=('')
#        sessions+=($session)
#    done
#done

# for day in ${days[@]};do
#         for hour in ${hours[@]};do
#                 echo ${day}_${hour}
#                 session='dailylife_cj611_'${day}'_'${hour}
#                 raw_data_dirs+=('')
#                 sessions+=($session)
#         done
# done
#for session in ${sessions[@]};do
#        echo $session
#done

# files_='/mnt/amakusa4/DataOrg/tkaneko/marmo2hoMotif/pogz/pogz1/isolation/p*.23506226'
# for filepath in ${files_[@]};do
#         tmp=${filepath##*/}
#         tmp2=${tmp%%.*}
#         sessions+=($tmp2)
#         raw_data_dirs+=('/mnt/amakusa4/DataOrg/tkaneko/marmo2hoMotif/pogz/pogz1/isolation')
# done

camNames=("23506214" "23506226" "23506236" "23506237" "23506239" "23511607" "23511613" "23511614")

sescnt=-1
for session in ${sessions[@]};do
        printf "%s\n", $session
        sescnt=`expr $sescnt + 1`
        # raw_data_dir=${raw_data_dirs[$sescnt]}
        echo $raw_data_dir
        data_name=$session

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
