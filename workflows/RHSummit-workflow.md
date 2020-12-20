# ChRIS FS->DS->DS plugin worflow summary

## Abstract

This page provides summary instructions for directly interacting with the CUBE backend to create the following Feed workflow:

```
⬤:N     N -- Indicates the instance id of the plugin
F|DS(K)  K -- Indicates plugin id

      ⬤:1        FS(10): pl-dircopy 
      |                  -- OR --
      |           FS(14): pl-mri10yr06mo01da_normal
      ↓
      ⬤:2        DS(12): pl-freesurfer_pp
     ╱│╲
    ╱ │ ╲
   ╱  │  ╲
  ╱   │   ╲
 ╱    │    ╲
↓     ↓     ↓ 
⬤:3  ⬤:4  ⬤:5  DS(11): pl-mpcs
│     │     │   
↓     ↓     ↓
⬤:6  ⬤:7  ⬤:8  DS(13): pl-z2labelmap

```

The set of operations are:

* instantiate CUBE;
  * if using ``pl-mri10yr06mo01da_normal`` then simply run the plugin;
  * if using ``pl-dircopy`` then after instantiation:
     * pull a sample dataset from github;
     * push into openstorage
     * run the ``pl-dircopy`` plugin
* run the FS data through ``pl-freesurfer_pp`` to create a FreeSurfer output (pre calculated on the FS output)
* run the FreeSurfer output through three parallel ``pl-mpcs`` plugins, each generating a different output
* run each of the 3 outputs through a ``pl-z2labelmap`` to create one of three sets of heat maps.

## Instantiate CUBE

Make sure you are in the base directory of the ChRIS_ultron_backEnd (CUBE) repo and importantly be sure to skip the unit and integration tests:

```bash
git clone https://github.com/FNNDSC/ChRIS_ultron_backEnd
cd ChRIS_ultron_backEnd

*destroy* ; sudo rm -fr FS; rm -fr FS ; *make* -U -I -i
```

### Set some convenience environment variables

```bash
export HOST_IP=$(ip route | grep -v docker | awk '{if(NF==11) print $9}')
export HOST_PORT=8000
```
## Create the Feed Using `pl-mri10yr06mo01da_normal` FS plugin

Determine the plugin instance ID of the plugin:

```bash
pfurl --auth chris:chris1234 --verb GET                          \
      --http ${HOST_IP}:${HOST_PORT}/api/v1/plugins/?limit=50    \
      --content-type application/vnd.collection+json             \
      --quiet --jsonpprintindent 4
```

and search for the `id` of the `pl-10yr06mo01da_normal` plugin. In this example, let's assume this to be 


```bash
pfurl --auth chris:chris1234 --verb POST                          \
      --http ${HOST_IP}:${HOST_PORT}/api/v1/plugins/14/instances/ \
      --content-type application/vnd.collection+json              \
      --jsonwrapper 'template' --msg '
{"data":
    [{"name":"dir",
      "value":"/usr/src/data"}
    ]
}' \
--quiet --jsonpprintindent 4
```

### Query and register output files

Query the status of the plugin job:

```bash
pfurl --auth chris:chris1234                               \
      --verb GET                                           \
      --http ${HOST_IP}:${HOST_PORT}/api/v1/plugins/instances/1/   \
      --content-type application/vnd.collection+json       \
      --quiet --jsonpprintindent 4
```

## Run the DICOMs pulled in the FS instance to ``pl-freesurfer_pp``

CLI equivalent 

```
mkdir in out && chmod 777 out
docker run --rm -v $(pwd)/in:/incoming -v $(pwd)/out:/outgoing      \
        fnndsc/pl-freesurfer_pp freesurfer_pp.py                    \
        -a 10-06-01                                                 \
        -c stats,sag,cor,tra,3D                                     \
        /incoming /outgoing
```

In the context of CUBE, 

```
pfurl --auth chris:chris1234 --verb POST \
--http ${HOST_IP}:${HOST_PORT}/api/v1/plugins/12/instances/ \
--content-type application/vnd.collection+json \
--jsonwrapper 'template' --msg '
{"data":
    [
     {"name":"ageSpec",
      "value":"10-06-01"},
     {"name":"copySpec",
      "value":"stats,sag,cor,tra,3D"},
     {"name":"previous_id",
      "value":"1"}
    ]
}' \
--quiet --jsonpprintindent 4
```

NOTE: Please be patient with this plugin. Due to the high volume of data, it can take several minutes to complete.

Query the results of the plugin call:

```bash
pfurl --auth chris:chris1234                               \
      --verb GET                                           \
      --http ${HOST_IP}:${HOST_PORT}/api/v1/plugins/instances/2/   \
      --content-type application/vnd.collection+json       \
      --quiet --jsonpprintindent 4
```

## The various MPC plugins feeding off the ``pl-freesurfer_pp`` output

The equivalent CLI call for the plugin would be

```bash
mkdir in out && chmod 777 out
docker run --rm -v $(pwd)/in:/incoming -v $(pwd)/out:/outgoing      \
        fnndsc/pl-mpcs mpcs.py                                      \
        --random --seed 1                                           \
        --posRange 3.0 --negRange -3.0                              \
        in out
```

which in the context of CUBE becomes

```bash
pfurl --auth chris:chris1234 --verb POST \
--http ${HOST_IP}:${HOST_PORT}/api/v1/plugins/11/instances/ \
--content-type application/vnd.collection+json \
--jsonwrapper 'template' --msg '
{"data":
    [
     {"name":"random",
      "value":true},
     {"name":"seed",
      "value":"1"},
     {"name":"posRange",
      "value":"3.0"},
     {"name":"negRange",
      "value":"-3.0"},
     {"name":"previous_id",
      "value":"2"}
    ]
}' \
--quiet --jsonpprintindent 4
```

and query the status of the call with

```bash
pfurl --auth chris:chris1234                               \
      --verb GET                                           \
      --http ${HOST_IP}:${HOST_PORT}/api/v1/plugins/instances/3/   \
      --content-type application/vnd.collection+json       \
      --quiet --jsonpprintindent 4
```

This call can take some time to complete, mostly due to data transfers. 

Repeat the plugin call two more times. Test the status of each with

### Instance 4

```bash
pfurl --auth chris:chris1234 --verb POST \
--http ${HOST_IP}:${HOST_PORT}/api/v1/plugins/11/instances/ \
--content-type application/vnd.collection+json \
--jsonwrapper 'template' --msg '
{"data":
    [
     {"name":"random",
      "value":true},
     {"name":"seed",
      "value":"1"},
     {"name":"posRange",
      "value":"3.0"},
     {"name":"negRange",
      "value":"-3.0"},
     {"name":"previous_id",
      "value":"2"}
    ]
}' \
--quiet --jsonpprintindent 4
```

```bash
pfurl --auth chris:chris1234                               \
      --verb GET                                           \
      --http ${HOST_IP}:${HOST_PORT}/api/v1/plugins/instances/4/   \
      --content-type application/vnd.collection+json       \
      --quiet --jsonpprintindent 4
```


### Instance 5

```bash
pfurl --auth chris:chris1234 --verb POST \
--http ${HOST_IP}:${HOST_PORT}/api/v1/plugins/11/instances/ \
--content-type application/vnd.collection+json \
--jsonwrapper 'template' --msg '
{"data":
    [
     {"name":"random",
      "value":true},
     {"name":"seed",
      "value":"1"},
     {"name":"posRange",
      "value":"3.0"},
     {"name":"negRange",
      "value":"-3.0"},
     {"name":"previous_id",
      "value":"2"}
    ]
}' \
--quiet --jsonpprintindent 4
```

```bash
pfurl --auth chris:chris1234                               \
      --verb GET                                           \
      --http ${HOST_IP}:${HOST_PORT}/api/v1/plugins/instances/5/   \
      --content-type application/vnd.collection+json       \
      --quiet --jsonpprintindent 4

```


## Run the ``pl-z2labelmap`` on each parallel branch

Now, finally, we will run the ``pl-z2labelmap`` on each branch of the ``pl-mpc`` output. The equivalent CLI call is

```bash
docker run --rm -v $(pwd)/in:/incoming -v $(pwd)/out:/outgoing  \
        fnndsc/pl-z2labelmap z2labelmap.py                      \
        --scaleRange 2.0 --lowerFilter 0.8                      \
        --negColor B --posColor R                               \
        /incoming /outgoing
```

Which, in each branch becomes:

### Branch ``ID:6 pl-z2labelmap``: connect to ``ID:3 pl-mpcs`` 

```bash
pfurl --auth chris:chris1234 --verb POST \
--http ${HOST_IP}:${HOST_PORT}/api/v1/plugins/13/instances/ \
--content-type application/vnd.collection+json \
--jsonwrapper 'template' --msg '
{"data":
    [
     {"name":"imageSet",
      "value":"../data/set1"},
     {"name":"negColor",
      "value":"B"},
     {"name":"posColor",
      "value":"R"},
     {"name":"previous_id",
      "value":"3"}
    ]
}' \
--quiet --jsonpprintindent 4
```

```bash
pfurl --auth chris:chris1234                               \
      --verb GET                                           \
      --http ${HOST_IP}:${HOST_PORT}/api/v1/plugins/instances/6/   \
      --content-type application/vnd.collection+json       \
      --quiet --jsonpprintindent 4
```


### Branch ``ID:7 pl-z2labelmap``: connect to ``ID:4 pl-mpcs`` 

```bash
pfurl --auth chris:chris1234 --verb POST \
--http ${HOST_IP}:${HOST_PORT}/api/v1/plugins/13/instances/ \
--content-type application/vnd.collection+json \
--jsonwrapper 'template' --msg '
{"data":
    [
     {"name":"imageSet",
      "value":"../data/set1"},
     {"name":"negColor",
      "value":"B"},
     {"name":"posColor",
      "value":"R"},
     {"name":"previous_id",
      "value":"4"}
    ]
}' \
--quiet --jsonpprintindent 4
```

```bash
pfurl --auth chris:chris1234                               \
      --verb GET                                           \
      --http ${HOST_IP}:${HOST_PORT}/api/v1/plugins/instances/7/   \
      --content-type application/vnd.collection+json       \
      --quiet --jsonpprintindent 4
```

### Branch ``ID:8 pl-z2labelmap``: connect to ``ID:5 pl-mpcs`` 

```bash
pfurl --auth chris:chris1234 --verb POST \
--http ${HOST_IP}:${HOST_PORT}/api/v1/plugins/13/instances/ \
--content-type application/vnd.collection+json \
--jsonwrapper 'template' --msg '
{"data":
    [
     {"name":"imageSet",
      "value":"../data/set1"},
     {"name":"negColor",
      "value":"B"},
     {"name":"posColor",
      "value":"R"},
     {"name":"previous_id",
      "value":"5"}
    ]
}' \
--quiet --jsonpprintindent 4
```

```bash
pfurl --auth chris:chris1234                               \
      --verb GET                                           \
      --http ${HOST_IP}:${HOST_PORT}/api/v1/plugins/instances/8/   \
      --content-type application/vnd.collection+json       \
      --quiet --jsonpprintindent 4
```


-30-