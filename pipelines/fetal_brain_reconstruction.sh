#!/bin/bash
# purpose: describe a pipeline to the ChRIS or ChRIS Store API.

# Step 0. specify ChRIS user.

CUBE_URL=${CUBE_URL:-http://localhost:8000/api/v1/}
CUBE_USER=${CUBE_USER:-chris:chris1234}

# Step 1. Upload these plugins.
# You probably have to do this step manually.

plugins=(
  https://chrisstore.co/api/v1/plugins/32/
  https://chrisstore.co/api/v1/plugins/3/
  https://chrisstore.co/api/v1/plugins/34/
  https://chrisstore.co/api/v1/plugins/4/
)

# If using miniChRIS, we can handle it for you using docker exec

CUBE_PORT="$(grep -Pom 1 '(?<=localhost:)[0-9].+(?=/api/v1/)' <<< "$CUBE_URL")"
MINICHRIS_PORTS="$(docker ps --filter label=org.chrisproject.info=miniChRIS --format '{{ .Ports }}')"

set -e

if [ -n "$CUBE_PORT" ] && [[ "$MINICHRIS_PORTS" = *"0.0.0.0:8000->"*"$CUBE_PORT/tcp"* ]]; then
  >&2 printf "Registering plugins to miniChRIS"
  for url in "${plugins[@]}"; do
    docker exec chris python plugins/services/manager.py register host --pluginurl $url
    >&2 printf .
  done
  >&2 echo
fi

# Step 2. POST the JSON representation to /api/v1/pipelines/

payload="$(
cat << EOF
{"template":
  {"data":[{"name":"name","value":"Automatic Fetal Brain Reconstruction Pipeline v1.0.0"},
  {"name": "authors", "value": "Jennings Zhang <Jennings.Zhang@childrens.harvard.edu>"},
  {"name": "Category", "value": "MRI"},
  {"name": "description", "value":
  "Automatic fetal brain reconstruction pipeline developed by Kiho's group at the FNNDSC. Features machine-learning based brain masking and quality assessment."},
  {"name":"locked","value":false},
  {"name":"plugin_tree","value":"[
    {\"plugin_name\":\"pl-fetal-brain-mask\"             ,\"plugin_version\":\"1.2.1\"    ,\"previous_index\":null},
    {\"plugin_name\":\"pl-ANTs_N4BiasFieldCorrection\"   ,\"plugin_version\":\"0.2.7.1\"  ,\"previous_index\":0,
      \"plugin_parameter_defaults\":[{\"name\":\"inputPathFilter\",\"default\":\"extracted/0.0/*.nii\"}]},
    {\"plugin_name\":\"pl-fetal-brain-assessment\"       ,\"plugin_version\":\"1.3.0\"   ,\"previous_index\":1},
    {\"plugin_name\":\"pl-irtk-reconstruction\"          ,\"plugin_version\":\"1.0.3\"   ,\"previous_index\":2}
  ]"}]}}
EOF
)"

curl -u "$CUBE_USER" "${CUBE_URL}pipelines/" \
  -H 'Content-Type:application/vnd.collection+json' \
  -H 'Accept:application/vnd.collection+json' \
  --data "$(tr -d '\n' <<< "$payload")"
