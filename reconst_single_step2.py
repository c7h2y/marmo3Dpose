# step 2
# extract one best detection in each camera

import pickle
import numpy as np
import yaml
import json
from tqdm import tqdm
import platform
import argparse
import os 


def proc(data_name,results_dir_root, config_path, n_kp,thr_kp_detection,redo=False):
    result_dir = results_dir_root+'/' + data_name
    if os.path.exists(result_dir + '/kp2d.pickle') & (not redo):
        print(f'Skip as exist:{data_name:s} ')
        return        

    with open(config_path, 'r') as f:
        cfg = yaml.safe_load(f)
    ID = cfg['camera_id']

    T = []
    for i_cam, id in enumerate(ID):

        with open(result_dir + '/' + str(id) + '/alldata.json', 'r') as f:
            data = json.load(f)

        T.append(data)

    n_cam = len(ID)
    n_frame = len(T[0])

    kp2d = np.zeros([1, n_frame, n_cam, n_kp, 3])
    for i_frame in tqdm(range(n_frame)):
        for i_cam in range(n_cam):
            TT = T[i_cam][i_frame]

            n_detected_kp = []
            for tt in TT:
                pose2d = np.array(tt[5])
                n = np.sum(pose2d[:,2]>thr_kp_detection)
                n_detected_kp.append(n)

            if len(n_detected_kp) < 1:
                continue

            n_detected_kp = np.array(n_detected_kp)
            i_best = np.argmax(n_detected_kp)
            
            tt = TT[i_best]
            pose2d = np.array(tt[5])

            kp2d[0,i_frame,i_cam,:,:] = pose2d

    with open(result_dir + '/kp2d.pickle', 'wb') as f:
        pickle.dump(kp2d, f)

if __name__ == '__main__':
    if 0: 
        data_name = 'dailylife_cj425_20220402_110000'
        if platform.system()=='Windows':
            raw_data_dir ='Y:/tkaneko/marmo2hoMotif/dailylife'
        else:
            raw_data_dir= '/mnt/amakusa4/DataOrg/tkaneko/marmo2hoMotif/dailylife'
        config_path = './calib/marmo/config.yaml'
        n_kp = 18
        thr_kp_detection = 0.5
        results_dir_root='./results3D'
    else:
        parser = argparse.ArgumentParser()    
        parser.add_argument('--data_name', default='', type=str, help='session name, e.g., dailylife_cj425_20220402_110000')    
        parser.add_argument('--results_dir_root', default='./results3D', help='Root directory to save 3D results')
        parser.add_argument('--config_path', default='./calib/marmo/config.yaml', help='Fullpath of config file')
        parser.add_argument('--n_kp', default=18, type=int, help='number of keypoints')
        parser.add_argument('--thr_kp_detection', default=0.5, type=float, help='threshold of key-point detection') 
        parser.add_argument('--redo', default=False, type=bool, help='redo and overwrite')
        args = parser.parse_args()
        data_name=args.data_name
        results_dir_root=args.results_dir_root
        config_path=args.config_path
        n_kp=args.n_kp
        thr_kp_detection=args.thr_kp_detection
        redo = args.redo
    proc(data_name,results_dir_root, config_path, n_kp,thr_kp_detection,redo)