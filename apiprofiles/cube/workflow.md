# Workflow

API resource representing a runtime instance (execution) of a [pipeline](pipeline). When 
users run a pipeline within the ChRIS platform they create a new workflow instance of the 
pipeline. This in turn creates a new [plugin instance](plugininstance.md) for each 
[plugin piping](piping.md) in the pipeline's connected directed acyclic graph (DAG). 
Thus the newly created plugin instances also form a connected DAG within the target 
[feed](feed.md) with the same topology as the pipeline's DAG.


## Semantic descriptors

* `id`: workflow unique identifier
* `creation_date`: workflow creation date
* `pipeline_id`: associate pipeline's unique identifier
* `pipeline_name`: associate pipeline's name  
* `created_plugin_inst_ids`: string representing a comma-separated list of the IDs of the 
plugin instances created by the workflow. The first ID in the list is the root of the 
DAG formed by the plugin instances.
* `owner_username`: username of the ChRIS user that created the workflow


## Link relations

* `pipeline`: points to the associated [pipeline](pipeline)
