This directory contains CLI scripts to run a segmentation workflow on ChRIS.

Follow the below steps to create a local CUBE instance, register constituent plugins, and run a segmentation workflow

### 1) Instantiate local CUBE

    Follow the instructions to set up CUBE : https://github.com/FNNDSC/ChRIS_ultron_backEnd
    
### 2) Add compute environments (Optional)
    Once CUBE is up, login to http://localhost:8000/chris-admin/login/?next=/chris-admin/.
    
    Add compute environments to CUBE.
    
### 3) Register plugins to compute environment(s)
    Now copy ``add_fastsurfer_plugins.sh`` to `ChRIS_ultron_backEnd` repo.
    
    Run the following command to register the constituent plugins to CUBE.
    

    ./add_fastsurfer_plugins.sh
    
    
    
### 4) Run CLI scripts to start a feed
    Since these scripts require `caw` to upload & register files to CUBE,
    we need to login to `caw` before running any of the segmentation scripts.
    

    caw logout
    caw --address http://localhost:8000/api/v1/ --username 'chris' login
    
### 5) View the feed in the ChRIS UI (Optional)

    Start a ChRIS UI instance by following the instructions provided here : https://github.com/FNNDSC/ChRIS_ui
    
