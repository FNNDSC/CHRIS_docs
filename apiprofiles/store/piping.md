# Plugin piping

API resource representing a node of the connected acyclic directed graph (DAG) that 
composes a [pipeline](pipeline.md). Each node represents a ChRIS [plugin](plugin.md) and 
its location within the pipeline's DAG. Note that the same plugin can show up in more 
than one node in the pipeline's DAG (i.e. same plugin associated with more than one 
piping). A piping's associated plugin must be of type `ds`.


## Semantic descriptors

* `id`: plugin piping unique identifier
* `previous_id`: unique identifier of the previous/parent piping in the pipeline DAG
* `plugin_id`: associated plugin's unique identifier
* `plugin_name`: associated plugin's name
* `plugin_version`: associated plugin's version
* `pipeline_id`: associated pipeline's unique identifier


## Link relations

* `plugin`: points to the associated [plugin](plugin.md) 
* `pipeline`: points to the associated [pipeline](pipeline.md)
* `previous`: points to the previous/parent piping in the pipeline DAG
