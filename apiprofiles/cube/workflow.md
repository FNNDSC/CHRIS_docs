# Workflow

API resource representing a runtime instance of a [pipeline](pipeline). When users run 
a pipeline in ChRIS they create a new workflow instance of the pipeline. This in turn 
creates a new plugin instance for each [plugin piping](piping.md) in the pipeline. 
Thus the newly created plugin instances also form a connected acyclic directed graph (DAG)
within the target [feed](feed.md).


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
