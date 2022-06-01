# Plugin

API resource representing a containerized command line program.

ChRIS plugins are of type `ds` (data synthesis), `fs` (feed synthesis) or `ts` 
(topology synthesis). 


## Semantic descriptors

* `id`: plugin unique identifier
* `creation_date`: creation/registration date
* `name`: plugin name
* `version`: plugin version
* `dock_image`: url of the plugin's docker image
* `title`: plugin title
* `stars`: number of users that has made the plugin a favorite plugin 
* `public_repo`: url of the source control repo for the plugin's source code 
* `license`: plugin release license 
* `type`: plugin type which can be one of `ds`, `fs` or `ts` 
* `icon`: url of an icon image for the plugin
* `category`: plugin category
* `authors`: string representing a comma separated list of author emails
* `description`: description of the plugin (can change across versions)
* `documentation`: url of a website or wiki page containing documentation about the 
  plugin
* `execshell`: absolute path to the plugin's execution shell within the container
* `selfpath`: absolute path to the plugin program within the container
* `selfexec`: file name of the plugin program
* `min_number_of_workers`: minimum required number of parallel workers
* `max_number_of_workers`: maximum allowed number of parallel workers
* `min_cpu_limit`: minimum required cpu limit
* `max_cpu_limit`: maximum allowed cpu limit
* `min_memory_limit`: minimum required memory limit
* `max_memory_limit`: maximum allowed memory limit
* `min_gpu_limit`: minimum required gpu limit
* `max_gpu_limit`: maximum allowed gpu limit


## Link relations

* `meta`: points to the related [plugin meta](pluginmeta.md)
* `parameters`: points to the collection of the plugin's command line parameters
