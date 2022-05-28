# Pipeline

API resource representing a set of ChRIS resources known as [plugin pipings](piping.md) 
that are organized as nodes of a connected acyclic directed graph (DAG). 
All the plugins associated to the pipings in the pipeline must be of type `ds`.


## Semantic descriptors

* `id`: pipeline unique identifier
* `creation_date`: pipeline creation date
* `modification_date`: pipeline modification date
* `name`: pipeline name  
* `locked`: boolean indicating whether the pipeline is published/accessible to users
other than the owner
* `category`: pipeline category
* `authors`: string representing a comma separated list of author emails
* `description`: pipeline description
* `owner_username`: username of the ChRIS user that created the pipeline


## Link relations

* `plugins`: points to the collection of [plugins](plugin.md) associated to the plugin 
  pipings composing the pipeline's DAG
* `plugin_pipings`: points to the collection of [plugin pipings](piping.md) composing the 
  pipeline's DAG
* `default_parameters`: points to the collection of default command line parameter values 
for the plugins associated to the pipings composing the pipeline's DAG
* `workflows`: points to the collection of runtime workflows created from the pipeline
