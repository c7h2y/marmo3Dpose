#!/bin/bash
source /opt/miniconda3/etc/profile.d/conda.sh

device_str="cuda:0"

config_path='./calib/marmo_cj425m/config.yaml' 
raw_data_dir='./vid'

label2d_dir='./results/2d_v0p8_Dark_fix_20'
vid2dout_dir='./results/video/2d_v0p8_dark_fix_20'
results3d_dir="./results/3d_v0p8_dark_fix_20"
vidout_dir='./results/video/3d_v0p8_dark_fix_20'
label2d_output_dir='./results/2d_v0p8_Dark_fix_20'

calib_3d_toml='./calibration_tmpl.toml'    
config_3d_toml='./config_tmpl.toml'

mkdir './results'
mkdir './video'
mkdir $label2d_dir
mkdir $results3d_dir
mkdir $video_dir
mkdir $vid2dout_dir
mkdir $vidout_dir

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
procFrame=100

# 2D Proc
flgDo=0

device_str="cuda:0" # hinai-
days=('20210903')
hours=('080000')
 

## 個体番号を適宜変える
for day in ${days[@]}; do
    for hour in ${hours[@]}; do
        echo ${day}_${hour}
        session='dailylife_cj611_'${day}'_'${hour}
        raw_data_dirs+=('')
        sessions+=($session)
    done
done

for session in ${sessions[@]};do
        echo $session
done 

camNames=("23506214" "23506226" "23506236" "23506237" "23506239" "23511607" "23511613" "23511614")

sescnt=-1
for session in ${sessions[@]};do
        sescnt=`expr $sescnt + 1`
        # raw_data_dir=${raw_data_dirs[$sescnt]}
        # echo $raw_data_dir 
        data_name=$session
        conda activate temp

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
                        --n_frame_to_save 10000
        done

        # 3D Proc 
        t_intv='None'        
        # conda activate multicam2
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
