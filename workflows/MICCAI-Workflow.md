# ChRIS FS->DS->DS plugin workflow summary

## Abstract
 The MICCAI work flow consists of 3 plug-ins.
 1) An FS plug-in `pl-test_data_generator` that initializes the feed and contains the test data
 2) A DS plug-in `pl-classification_test` that tests the classifier on the test data from the previous plug-in
 3) A DS plug-in `pl-cni_challenge_evaluation` that evaluates the test results from the previous plug-in and generates an accuracy score

The overall linear work-flow looks like the below

```
`pl-test_data_generator` -> `pl-classification_test` -> `pl-cni_challenge_evaluation`
```


## Assumptions
1. You have a CUBE instance already up and running and listening at port 8000
2. You have instantiated CUBE without integration tests
3. You are using a python virtual environment to execute the following commands
4. You have libraries like pfurl, httpie, swift-client, installed in the virtual env

Open a new terminal and get inside the python virtual environment and follow the below steps in order

## Set some convenience environment variables

```

export HOST_IP=$(ip route | grep -v docker | awk '{if(NF==11) print $9}')
export HOST_PORT=8000

alias pfurl='docker run --rm --name pfurl fnndsc/pfurl'

```

## Upload and register the FS plugin
```
docker run --rm -v /tmp/json:/json sandip117/pl-test_data_generator test_data_generator.py --savejson /json

http -a cubeadmin:cubeadmin1234 -f POST http://${HOST_IP}:8010/api/v1/plugins/ dock_image=sandip117/pl-test_data_generator descriptor_file@/tmp/json/Test_data_generator.json public_repo=https://github.com/sandip117/pl-test_data_generator name=test_data_generator 

```

## Clear pman DB

```
pfurl --verb POST --raw --http ${HOST_IP}:5010/api/v1/cmd \
      --jsonwrapper 'payload' --msg \
 '{  "action": "DBctl",
         "meta": {
                 "do":     "clear"
         }
 }' --quiet --jsonpprintindent 4

```
## Create the Feed

```

pfurl --auth chris:chris1234 --verb POST                          \
      --http ${HOST_IP}:${HOST_PORT}/api/v1/plugins/13/instances/ \
      --content-type application/vnd.collection+json              \
      --jsonwrapper 'template' --msg '
{"data":
    [{"name":"dir",
      "value":"/usr/src/data"}
    ]
}' \
--quiet --jsonpprintindent 4
```

## Query and register output files

```
pfurl --auth chris:chris1234                               \
      --verb GET                                           \
      --http ${HOST_IP}:${HOST_PORT}/api/v1/plugins/instances/1/   \
      --content-type application/vnd.collection+json       \
      --quiet --jsonpprintindent 4

```
## Check the list of the files

```

pfurl --auth chris:chris1234                               \
      --verb GET                                           \
      --http ${HOST_IP}:${HOST_PORT}/api/v1/1/files/       \
      --content-type application/vnd.collection+json       \
      --quiet --jsonpprintindent 4

```

## Upload and register first DS plugin

```

docker run --rm -v /tmp/json:/json aiwc/classification_test classification_test.py --savejson /json



http -a cubeadmin:cubeadmin1234 -f POST http://${HOST_IP}:8010/api/v1/ dock_image=aiwc/classification_test descriptor_file@/tmp/json/classification_test.json public_repo=https://github.com/aichung/pl-classification_test name=classification_test

```
## Run the DS plugin

```
http -a chris:chris1234 POST http://${HOST_IP}:8000/api/v1/plugins/13/instances/ \
Content-Type:application/vnd.collection+json \
Accept:application/vnd.collection+json \
template:='{"data":
    [
     {"name":"previous_id",
      "value":"1"}
    ]
}'
```

## Query and register output files

```

pfurl --auth chris:chris1234                               \
      --verb GET                                           \
      --http ${HOST_IP}:${HOST_PORT}/api/v1/plugins/instances/2/   \
      --content-type application/vnd.collection+json       \
      --quiet --jsonpprintindent 4



```
## View the list of the files

```

pfurl --auth chris:chris1234                               \
      --verb GET                                           \
      --http ${HOST_IP}:${HOST_PORT}/api/v1/plugins/instances/2/files/       \
      --content-type application/vnd.collection+json       \
      --quiet --jsonpprintindent 4

```

## Upload and register the second DS plugin

```

docker run --rm -v /tmp/json:/json aiwc/cni_challenge_evaluation cni_challenge_evaluation.py --savejson /json



http -a cubeadmin:cubeadmin1234 -f POST http://${HOST_IP}:8010/api/v1/ dock_image=aiwc/cni_challenge_evaluation descriptor_file@/tmp/json/cni_challenge_evaluation.json public_repo=https://github.com/aichung/pl-cni_challenge_evaluation name=cni_challenge_evaluation

```

## Run the second DS plug-in

```

http -a chris:chris1234 POST http://${HOST_IP}:8000/api/v1/plugins/14/instances/ \
Content-Type:application/vnd.collection+json \
Accept:application/vnd.collection+json \
template:='{"data":
    [
     {"name":"previous_id",
      "value":"2"}
    ]
}'

```

## Query and register the output files

```

pfurl --auth chris:chris1234                               \
      --verb GET                                           \
      --http ${HOST_IP}:${HOST_PORT}/api/v1/plugins/instances/3/   \
      --content-type application/vnd.collection+json       \
      --quiet --jsonpprintindent 4

```

## View the list of the files created

```

pfurl --auth chris:chris1234                               \
      --verb GET                                           \
      --http ${HOST_IP}:${HOST_PORT}/api/v1/plugins/instances/3/files/       \
      --content-type application/vnd.collection+json       \
      --quiet --jsonpprintindent 4

```

## The over all workflow ends here
 You can view the output files generated in the swift storage by 

```
cd ChRIS_ultron_backEnd/utils/scripts
./swiftCtl.sh

```
You should see the list of the output files inside the storage

