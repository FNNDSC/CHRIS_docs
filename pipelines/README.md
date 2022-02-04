# ChRIS pipelines

## Abstract

The concept of a **ChRIS Pipeline** is a still evolving idea. At its core, a **Pipeline** is a structured description a program (or several programs) _and_ all parameters (and meta data) pertinent to using this program (or programs). 

While the word *pipeline* might suggest a *collection* (i.e. _N > 1_) of compute elements (programs, or in the case of ChRIS _plugins_), a *pipeline* of just one plugin can still be a valid **ChRIS pipeline**. Why might a single plugin pipeline be useful? Simply because it can act as an _alias_ or describe fully one manner in which to use (and re-use) the plugin in an extremely simple fashion.

This directory contains a collection of JSON specified ChRIS pipelines that can be uploaded to a ChRIS instance to perform some useful functions.

## Available Pipelines

See the `source` directory.

### `covidnet_simple.json` 

A pipeline that accepts as input a single CT image and ultimately produces a report predicting the image to either

* show COVID infection
* show pneumonia
* normal

### `fetal_brain_reconstruction.json`

A pipeline that accepts as input several NIfTI volumes of maternal scans containing a fetus and produces as output a single image cropped to and only showing the fetal brain.

### `DICOM_anonymization.json`

A pipeline that accepts DICOM images and produces as output copies of those images with meta header data appropriately anonymized.

## How to upload

The shell script, `pipeline_upload.sh`, can be used to upload a pipeline JSON file to a ChRIS instance. In its simplest case, to upload `mypipeline.json` to a ChRIS instance running on `localhost`, simply do

```bash
pipeline_upload.sh --pipelineFile mypipeline.json --
```

usually, however, the ChRIS instance will not be on `localhost` but accessible from some IP address. In that case:

```bash
pipeline_upload.sh -a some.address.com --pipelineFile mypipeline.json --
```

Please see `pipeline_upload.sh -v` for more inline options.

### Prerequisites

The script relies on some command line tools that might not be normally installed. These are `jq` for JSON handling from the shell, and the `npm` nodejs tool `chripon`.



_-30-_

