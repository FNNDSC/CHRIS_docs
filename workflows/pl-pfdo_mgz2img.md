`pl-pfdo_mgz2img` Workflow
---------------------------

This workflow mainly guides you on how to use output mgz files from the `pl-freesurfer_pp` or `pl-fshack` plugins to run the `pl-pfdo_mgz2image` and convert the mgz files to readable image formats like png/jpg. This will also be helpful in knowing the exact parameters to pass to replicate this workflow on the `ChRIS_ui`.

There are 2 workflows explained in this markdown. 
1. `pl-fshack` -> `pl-pfdo_mgz2img`
2. `pl-freesurfer` -> `pl-pfdo_mgz2img`

Pipeline-1 : pl-fshack -> pl-pfdo_mgz2image
--------------------------------------------

1. Pull all the required docker images.
   
   <pre><code>docker pull fnndsc/pl-fshack \
   docker pull fnndsc/pl-pfdo_mgz2img
   </pre></code>

2. Get input DICOM data for `pl-fshack` and run. This converts the DICOM files to an mgz volume. (The results folder contains both mgz volumes: with and without the skull stripped)
   
   <pre><code>
   cd ~/                                              
   mkdir devel                                       
   cd devel  
   mkdir results                                        
   export DEVEL=$(pwd)                               
   git clone https://github.com/FNNDSC/SAG-anon.git
   </pre></code>

   Now, run the pl-fshack docker container. 
   
   <pre><code>
   docker run --rm -ti                                                 \
      -v ${DEVEL}/SAG-anon-nii/:/incoming -v ${DEVEL}/results/:/outgoing  \
      fnndsc/pl-fshack fshack.py                                          \
      -i 0001-1.3.12.2.1107.5.2.19.45152.2013030808110258929186035.dcm    \                                                                \
      -o recon-of-SAG-anon                                                \
      --exec recon-all                                                    \
      --args 'ARGS: -autorecon1'                                          \
      /incoming /outgoing
   </pre></code>

3. Run `pl-pfdo_mgz2img` on the results of the previous plugin.

   <pre><code>
   mkdir mgz2image_results
   </pre></code>
   
   <pre><code>
   docker run --rm -ti                                                  \
      -v ${DEVEL}/results/:/incoming                                       \
      -v ${DEVEL}/mgz2image_results/:/outgoing                             \
      fnndsc/pl-pfdo_mgz2img pfdo_mgz2img                                  \
      --filterExpression mgz                                               \
      --saveImages                                                         \
      --lookupTable __none__                                               \
      --skipAllLabels                                                      \
      --printElapsedTime                                                   \
      --verbose 5                                                          \
      /incoming /outgoing
   </pre></code>

Pipeline-2 : pl-freesurfer_pp -> pl-pfdo_mgz2image
---------------------------------------------------

1. Pull all the required docker images.
   
   <pre><code>docker pull fnndsc/pl-freesurfer_pp \
   docker pull fnndsc/pl-pfdo_mgz2img
   </pre></code>

2. Run the pre-populated dummy plugin `pl-freesurfer_pp` to generate sample MGZ volumes.

   <pre><code>
   cd ~/                                              
   mkdir devel                                       
   cd devel  
   mkdir results                                        
   export DEVEL=$(pwd)                               
   </pre></code>
   
   Now, run the pl-freesurfer_pp docker container. 
   <pre><code>
   docker run --rm                                             \
      -v ${DEVEL}/:/incoming -v ${DEVEL}/results/:/outgoing       \
      fnndsc/pl-freesurfer_pp freesurfer_pp.py                    \
      -a 10-06-01                                                 \
      -c mri                                                      \
      /incoming /outgoing

3. Run `pl-pfdo_mgz2img` on the results of the previous plugin.

   <pre><code>
   mkdir mgz2image_results
   </pre></code>
   
   <pre><code>
   docker run --rm -ti                                                  \
      -v ${DEVEL}/results/:/incoming                                       \
      -v ${DEVEL}/mgz2image_results/:/outgoing                             \
      fnndsc/pl-pfdo_mgz2img pfdo_mgz2img                                  \
      --filterExpression mgz                                               \
      --saveImages                                                         \
      --lookupTable __none__                                               \
      --skipAllLabels                                                      \
      --printElapsedTime                                                   \
      --verbose 5                                                          \
      /incoming /outgoing
   </pre></code>
   
   
**NOTE:**

The above commands to run `pl-pfdo_mgz2img` use the argument `--lookupTable __none__` which will create unlabelled raw JPG/PNG images. If you want RBG images based on labelled cortical segments using the `FreeSurferColorLUT.txt` file, you must change the argument to `--lookupTable __fs__`. 

