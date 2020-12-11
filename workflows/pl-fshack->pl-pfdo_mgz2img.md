pl-fshack -> pl-pfdo_mgz2image
-------------------------------

1. Pull all the required docker images.
   
   <pre><code>docker pull fnndsc/pl-fshack \
   docker pull fnndsc/pl-pfdo_mgz2img
   </pre></code>

2. Get input DICOM data for `pl-fshack` and run.
   
   <pre><code>
   cd ~/                                              
   mkdir devel                                       
   cd devel  
   mkdir results                                        
   export DEVEL=$(pwd)                               
   git clone https://github.com/FNNDSC/SAG-anon.git
   </pre></code>

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
