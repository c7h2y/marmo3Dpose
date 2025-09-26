dataset_info = dict(
    dataset_name='marmoset20',
    paper_info=dict(
        author='None'       
        'None',
        title='None',
        container='None',
        year='None',
        homepage='None'
        'None',
    ),
    keypoint_info={
        0:
        dict(name='nose', id=0, color=[51, 153, 255], type='upper', swap=''),
        1:
        dict(
            name='L eye',
            id=1,
            color=[51, 153, 255],
            type='upper',
            swap='R eye'),
        2:
        dict(
            name='R eye',
            id=2,
            color=[51, 153, 255],
            type='upper',
            swap='L eye'),
        3:
        dict(
            name='L ear',
            id=3,
            color=[51, 153, 255],
            type='upper',
            swap='R ear'),
        4:
        dict(
            name='R ear',
            id=4,
            color=[51, 153, 255],
            type='upper',
            swap='L ear'),
        5:
        dict(
            name='L shoulder',
            id=5,
            color=[0, 255, 0],
            type='upper',
            swap='R shoulder'),
        6:
        dict(
            name='R shoulder',
            id=6,
            color=[255, 128, 0],
            type='upper',
            swap='L shoulder'),
        7:
        dict(
            name='L elbow',
            id=7,
            color=[0, 255, 0],
            type='upper',
            swap='R elbow'),
        8:
        dict(
            name='R elbow',
            id=8,
            color=[255, 128, 0],
            type='upper',
            swap='L elbow'),
        9:
        dict(
            name='L wrist',
            id=9,
            color=[0, 255, 0],
            type='upper',
            swap='R wrist'),
        10:
        dict(
            name='R wrist',
            id=10,
            color=[255, 128, 0],
            type='upper',
            swap='L wrist'),
        11:
        dict(
            name='L hip',
            id=11,
            color=[0, 255, 0],
            type='lower',
            swap='R hip'),
        12:
        dict(
            name='R hip',
            id=12,
            color=[255, 128, 0],
            type='lower',
            swap='L hip'),
        13:
        dict(
            name='L knee',
            id=13,
            color=[0, 255, 0],
            type='lower',
            swap='R knee'),
        14:
        dict(
            name='R knee',
            id=14,
            color=[255, 128, 0],
            type='lower',
            swap='L knee'),
        15:
        dict(
            name='L ankle',
            id=15,
            color=[0, 255, 0],
            type='lower',
            swap='R ankle'),
        16:
        dict(
            name='R ankle',
            id=16,
            color=[255, 128, 0],
            type='lower',
            swap='L ankle'),
        17:
        dict(
            name='backbone peak',
            id=17,
            color=[233, 163, 38],
            type='lower',
            swap=''),
        
        18:
        dict(
            name='tail_1',
            id=18,
            color=[255, 255, 255],
            type='lower',
            swap=''),
        
        19:
        dict(
            name='tail_2',
            id=19,
            color=[255, 255, 255],
            type='lower',
            swap=''),


    },
    skeleton_info={
        0:
        dict(link=('L ankle', 'L knee'), id=0, color=[0, 255, 0]),
        1:
        dict(link=('L knee', 'L hip'), id=1, color=[0, 255, 0]),
        2:
        dict(link=('R ankle', 'R knee'), id=2, color=[255, 128, 0]),
        3:
        dict(link=('R knee', 'R hip'), id=3, color=[255, 128, 0]),
        4:
        dict(link=('L hip', 'R hip'), id=4, color=[51, 153, 255]),
        5:
        dict(link=('L shoulder', 'L hip'), id=5, color=[51, 153, 255]),
        6:
        dict(link=('R shoulder', 'R hip'), id=6, color=[51, 153, 255]),
        7:
        dict(
            link=('L shoulder', 'R shoulder'),
            id=7,
            color=[51, 153, 255]),
        8:
        dict(link=('L shoulder', 'L elbow'), id=8, color=[0, 255, 0]),
        9:
        dict(
            link=('R shoulder', 'R elbow'), id=9, color=[255, 128, 0]),
        10:
        dict(link=('L elbow', 'L wrist'), id=10, color=[0, 255, 0]),
        11:
        dict(link=('R elbow', 'R wrist'), id=11, color=[255, 128, 0]),
        12:
        dict(link=('L eye', 'R eye'), id=12, color=[51, 153, 255]),
        13:
        dict(link=('nose', 'L eye'), id=13, color=[51, 153, 255]),
        14:
        dict(link=('nose', 'R eye'), id=14, color=[51, 153, 255]),
        15:
        dict(link=('L eye', 'L ear'), id=15, color=[51, 153, 255]),
        16:
        dict(link=('R eye', 'R ear'), id=16, color=[51, 153, 255]),
        17:
        dict(link=('L ear', 'L shoulder'), id=17, color=[51, 153, 255]),
        18:
        dict(link=('R ear', 'R shoulder'), id=18, color=[51, 153, 255]), 
        19:
        dict(link=('backbone peak', 'R shoulder'), id=19, color=[51, 153, 255]),
        20:
        dict(link=('backbone peak', 'L shoulder'), id=20, color=[51, 153, 255]),
        21:
        dict(link=('backbone peak', 'R hip'), id=21, color=[51, 153, 255]),
        22:
        dict(link=('backbone peak', 'L hip'), id=22, color=[51, 153, 255]),
        23:
        dict(link=('backbone peak', 'tail_1'), id=23, color=[255, 255, 255]),
        24:
        dict(link=('tail_1', 'tail_2'), id=23, color=[255, 255, 255])
    },
    joint_weights=[
        1., 1., 1., 1., 1., 1., 1., 1.2, 1.2, 1.5, 1.5, 1., 1., 1.2, 1.2, 1.5,
        1.5,1, 1, 1
    ],
    sigmas=[
        0.026, 0.025, 0.025, 0.035, 0.035, 0.079, 0.079, 0.072, 0.072, 0.062,
        0.062, 0.107, 0.107, 0.087, 0.087, 0.089, 0.089, 0.089, 0.089, 0.089
    ])
