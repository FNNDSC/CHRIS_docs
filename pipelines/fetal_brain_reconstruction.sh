#!/bin/bash -e

plugins=(
  https://chrisstore.co/api/v1/plugins/71/
  https://chrisstore.co/api/v1/plugins/77/
  https://chrisstore.co/api/v1/plugins/81/
  https://chrisstore.co/api/v1/plugins/89/
)

for url in "${plugins[@]}"; do
  docker exec chris python plugins/services/manager.py register host --pluginurl $url
done

payload="$(
cat << EOF
{"template":
  {"data":[{"name":"name","value":"Automatic Fetal Brain Reconstruction Pipeline"},
  {"name": "authors", "value": "Jennings Zhang <Jennings.Zhang@childrens.harvard.edu>"},
  {"name": "Category", "value": "MRI"},
  {"name": "description", "value":
  "Automatic fetal brain reconstruction pipeline developed by Kiho's group at the FNNDSC. Features machine-learning based brain masking and quality assessment."},
  {"name":"locked","value":false},
  {"name":"plugin_tree","value":"[
    {\"plugin_name\":\"pl-fetal-brain-mask\"             ,\"plugin_version\":\"1.2.1\"    ,\"previous_index\":null},
    {\"plugin_name\":\"pl-ants_n4biasfieldcorrection\"   ,\"plugin_version\":\"0.2.7.1\"  ,\"previous_index\":0,
      \"plugin_parameter_defaults\":[{\"name\":\"inputPathFilter\",\"default\":\"extracted/0.0/*.nii\"}]},
    {\"plugin_name\":\"pl-fetal-brain-assessment\"       ,\"plugin_version\":\"1.3.0\"   ,\"previous_index\":1},
    {\"plugin_name\":\"pl-irtk-reconstruction\"          ,\"plugin_version\":\"1.0.3\"   ,\"previous_index\":2}
  ]"}]}}
EOF
)"

curl -u chris:chris1234 http://localhost:8000/api/v1/pipelines/ \
  -H 'Content-Type:application/vnd.collection+json' \
  -H 'Accept:application/vnd.collection+json' \
  --data "$(tr -d '\n' <<< "$payload")"
