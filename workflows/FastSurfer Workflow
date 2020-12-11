pl-fshack -> pl-fastsurfer_inference -> pl-mgz2lut_report
---------------------------------------------------------------

********************************* FastSurfer Workflow ******************************************

Step 1) Pull all the docker images

    docker pull fnndsc/pl-fshack         \
    docker pull fnndsc/pl-fastsurfer_inference \
    docker pull fnndsc/pl-mgz2lut_report
    
Step 2) Get input data for 'pl-fshack' & run


    cd ~/                                              
    mkdir devel                                       
    cd devel                                          
    export DEVEL=$(pwd)                               
    git clone https://github.com/FNNDSC/SAG-anon-nii.git
    
    docker run --rm                                                         \
    -v ${DEVEL}/SAG-anon-nii/:/incoming -v ${DEVEL}/results/:/outgoing  \
    fnndsc/pl-fshack fshack.py                                          \
    -i SAG-anon.nii                                                     \
    -o recon-of-SAG-anon-nii                                            \
    --exec recon-all                                                    \
    --args 'ARGS: -autorecon1'                                    \
    /incoming /outgoing
    
Step 3) Run 'pl-fastsurfer_inference' on the results of the previous plugin

    docker run --rm                                                         \
    -v ${DEVEL}/results/recon-of-SAG-anon-nii/mri/:/incoming -v ${DEVEL}/inference_results/:/outgoing  \
    fnndsc/pl-fastsurfer_inference fastsurfer_inference.py                                          \
    --t .                                                     \
    --in_name brainmask.mgz                                   \                    
    /incoming /outgoing
    
    
Step 4) Run 'pl-mgz2lut_report' on the results of the previous plug-in

    docker run --rm                                                         \
    -v ${DEVEL}/inference_results/:/incoming -v ${DEVEL}/mgz_reports/:/outgoing  \
    fnndsc/pl-mgz2lut_report mgz2lut_report.py                                          \
    --file_name aparc.DKTatlas+aseg.deep.mgz                                                     \
    --report_name simpleMGZReport                                   \ 
    --report_types csv,json,pdf,txt                                    \                
    /incoming /outgoing


# Run the work-flow on CLI using CUBE (`pl-dircopy` -> `pl-fshack` -> `pl-fastsurfer_inference` -> `pl-mgz2lut_report`)

## Set some environment variables

```
export HOST_IP=$(ip route | grep -v docker | awk '{if(NF==11) print $9}')
export HOST_PORT=8000

alias pfurl='docker run --rm --name pfurl fnndsc/pfurl'
```

## Clear pman

```
pfurl --verb POST --raw --http ${HOST_IP}:5010/api/v1/cmd \
      --jsonwrapper 'payload' --msg \
 '{  "action": "DBctl",
         "meta": {
                 "do":     "clear"
         }
 }' --quiet --jsonpprintindent 4
```

## Push data to Swift

```
export DICOMDIR=$(pwd)/SAG-anon
cd ChRIS_ultron_backEnd
cd utils/scripts
./swiftCtl.sh -A push -E dcm -D $DICOMDIR -P chris/uploads/DICOM/dataset1
```
## Run pl-dircopy

```
pfurl --auth chris:chris1234 --verb POST                         \
      --http ${HOST_IP}:${HOST_PORT}/api/v1/plugins/5/instances/ \
      --content-type application/vnd.collection+json             \
      --jsonwrapper 'template' --msg '
{"data":
    [{"name":"dir",
      "value":"chris/uploads/DICOM/dataset1"}
    ]
}' \
--quiet --jsonpprintindent 4
```

## Run pl-fshack

```
furl --auth chris:chris1234 --verb POST                         \
      --http ${HOST_IP}:${HOST_PORT}/api/v1/plugins/13/instances/ \
      --content-type application/vnd.collection+json             \
      --jsonwrapper 'template' --msg '
{"data":
    [{"name":"args",
      "value":"\\\"ARGS: -autorecon1\\\" "},
      {"name":"previous_id",
       "value":"1"},
      {"name":"exce",
       "value":"recon-all"},
      {"name":"inputFile",
       "value":"0001-1.3.12.2.1107.5.2.19.45152.2013030808110258929186035.dcm"},
      {"name":"outputFile",
       "value":"recon-of-SAG-anon-dcm"}
    ]
}' \
--quiet --jsonpprintindent 4
```
## Run pl-fastsurfer_inference

```
pfurl --auth chris:chris1234 --verb POST                         \
      --http ${HOST_IP}:${HOST_PORT}/api/v1/plugins/14/instances/ \
      --content-type application/vnd.collection+json             \
      --jsonwrapper 'template' --msg '
{"data":
    [{"name":"search_tag",
      "value":"recon-of-SAG-anon/mri"},
      {"name":"previous_id",
       "value":"2"},
      {"name":"cleanup",
       "value":"true"},
      {"name":"in_name",
       "value":"brainmask.mgz"}
    ]
}' \
--quiet --jsonpprintindent 4
```

## Run pl-mgz2lut_report
```
`pfurl --auth chris:chris1234 --verb POST                         \
      --http ${HOST_IP}:${HOST_PORT}/api/v1/plugins/15/instances/ \
      --content-type application/vnd.collection+json             \
      --jsonwrapper 'template' --msg '
{"data":
    [{"name":"file_name",
      "value":"100307/aparc.DKTatlas+aseg.deep.mgz"},
      {"name":"previous_id",
       "value":"3"}
    ]
}' \
--quiet --jsonpprintindent 4


```


