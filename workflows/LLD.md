# Leg Length Discrepancy(LLD) analysis of Leg Images
The LLD analysis is one of the most used workflows in ChRIS. The workflow starts with Leg X-rays as DICOM files and 
ends with a new DICOM generated, that has measurements of Tibia and Femur of both legs. Apart from their lengths, these
measurements also include differences between the left and right leg. The measurements are typically expressed in cm, 
however, sometimes(when a suitable scaling parameter is not present) these are also expressed in pixels.

While the explanation of how the input DICOM ended up in ChRIS is interesting in itself, it's beyond the scope of the
current topic. This document offers explanation of how the input file goes through multiple image and text processing 
applications or _plugins_ until we have a final DICOM that contains information about measurements and their discrepancy
in both the left and right leg. In order to calculate the length of tibia and femur of a leg, we need to determine its
hip, knee, and ankle joint first. We use an ML plugin, `pl-lld_inference`, to determine the (x,y) coordinates of these joints.
After that, we use an image processing plugin `pl-markimg` to use these coordinates to draw onto the input image, 
calculate the lengths of parts of individual legs, and provide a comparison between these calculations made. Finally,
we convert this image with additional information to a DICOM file using a plugin ``pl-dicommake``.

There are other plugins in this workflow that offers filtering, converting, checking, and aggregating data within the workflow as well.
We explain them in subsequent sections below.


## Analysis tree

```mermaid
   stateDiagram-v2
    dircopy --> unstack_folders: flatten directory structure
    unstack_folders --> dylld: dynamically create the LLD workflow on input
    unstack_folders --> shexec: copy input to output directory
    shexec --> dcm2mha_cnvtr: convert the input DICOMs to mha
    state topologicalcopy1 <<join>>
    state topologicalcopy2 <<join>>
    state topologicalcopy3 <<join>>
    shexec --> topologicalcopy2: filter dcm
    topologicalcopy2 --> csv2json: convert prediction.csv file to usable JSON
    topologicalcopy2 --> topologicalcopy3: filter dcm
    topologicalcopy3 --> lld_chxr: check the quality of measurements made by LLD analysis
    lld_chxr --> dicommake: create DICOM from input image
    lld_chxr --> neurofiles_push2: push a analysis report on the measurements to neuro FS
    dicommake --> dicom_dirsend: send final DICOM generated to a remote PACS 
    csv2json --> topologicalcopy1: filter json
    dcm2mha_cnvtr --> lld_inference: predict heatmap checkpoints on input files
    lld_inference --> topologicalcopy1: filter jpg
    lld_inference --> topologicalcopy2: filter csv
    topologicalcopy1 --> markimg: burn PHI and report measurements between L/R leg joints
    markimg --> neurofiles_push1: push a measurement summary JSON to neuro FS
    markimg --> topologicalcopy3: filter all
    
```

## List of plugins used
### 1) pl-dylld (https://github.com/FNNDSC/pl-dylld)

This plugin creates a dynamic LLD analysis in ChRIS on the input Leg X-Rays. It expects a DICOM file in it's input directory. 
It requires the following pipelines  to be registered to the CUBE instance on which the plugin runs:

  1. Leg Length Discrepency inference on DICOM inputs v20230324-1 using CPU
  2. PNG-to-DICOM and push to PACS v20230324
  3. Leg Length Discrepency measurements on image v20230324
  4. Leg Length Discrepency prediction formatter v20230324

pl-dylld uses topological joins to aggregate data and add these pipelines to the workflow dynamically. It's a blocking 
plugin, meaning it waits till the entire LLD workflow finishes running on CUBE.

### 2) pl-shexec (https://github.com/FNNDSC/pl-shexec)
This plugin simply copies the input file, conforming to the specified file filter, to it's output directory.

### 3) pl-dcm2mha (https://github.com/FNNDSC/pl-dcm2mha)
This plugin converts the incoming DICOMs to .mha format and rotates the image 90 degrees anticlockwise. 
The downstream ML plugin ``pl-lld_inference`` expects a .mha file as input with this particular orientation for predicting
landmark points on the leg image.

### 4) pl-csv2json (https://github.com/FNNDSC/pl-csv2json)
This plugin expects an input dicom file and a csv file containing anatomical landmark points and serialize these information
to an output JSON file. The JSON file contains PHI that were extracted from the input DICOM, and x-y coordinates about 
joints like hips, ankles, and knees that the plugin interprets from the input csv file.

### 5) pl-lld_inference (https://github.com/FNNDSC/pl-lld_inference)
This plugin is an ML application that takes in an input Leg image as a .mha file. The plugin predicts landmark points to 
represent various joints. These points(x-y coordinates) are recorded in a .csv file. The plugin also generates heatmap images
of the leg joints.

You can also find input images of the Leg as a jpg file in the plugin's output directory.

### 6) pl-topologicalcopy (https://github.com/FNNDSC/pl-topologicalcopy)
This plugin filters and aggregates data from multiple nodes in a CUBE analysis to an output directory. We use this plugin 
at various points in the LLD workflow to provide necessary data to downstream plugins for further processing.

### 7) pl-markimg (https://github.com/FNNDSC/pl-markimg)
This plugin uses the ``matplotlib`` library to measure and calculate leg lengths and draw joints on the input leg image.
It expects an input image as well as a JSON file containing information such as PHI and different joints in the leg such
as hips, knees, and ankles respectively. 

The plugin also burns these information on the image. Finally, before saving, the plugin autoscales and rotates the 
image 90 degrees clockwise using `pillow` to conform to the original input DICOM.

### 8) pl-dicommake (https://github.com/FNNDSC/pl-dicommake)
This plugin is responsible to "DICOMize" an input image, given another input DICOM that contains a list of suitable file meta.
The plugin replaces the existing _PixelData_ from the input DICOM with the input image. It then dynamically adjust certain 
tags such as _PhotometricInterpretation_ and other image related tags before assigning the DICOM with a new _SeriesInstanceUID_.

Finally, the plugin also accepts an option parameter to compress the output DICOM file using **JPEG2000** encoding.

### 9) pl-lld_chxr (https://github.com/FNNDSC/pl-lld_chxr)
This plugin offers Quality Assurance(QA) of the results generated by the LLD analysis. It ensures that the output data
generated conforms to certain required standards and the measurements of legs are within a specific limit. The plugin also
checks for missing DICOM tags and appropriate measurement units.

The goal of this plugin is to only allow "valid" output downstream to be sent to remote PACS. It generated a _status_ file
towards the end of its execution that offers valuable information regarding the quality of the output DICOM.

### 10) pl-neurofiles-push (available in rc-gitlab)
This plugin pushes analysis files (JSON) generated in the workflow to a directory located in `/neuro` tree. These files 
can offer important insights into the nature of input vs output data and to perform other helpful data analysis algorithms.

### 11) pl-dicom_dirsend (https://github.com/FNNDSC/pl-dicom_dirsend)
This plugin pushes DICOM files from an input directory to a remote PACS. After the LLD analysis is finished and an 
appropriate output DICOM image is generated, `pl-dicom_dirsend` sends this DICOM to **SYNAPSERESEARCH** using the 
``dcmsend`` application available in `dcmtk` library.