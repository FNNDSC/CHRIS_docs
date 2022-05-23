# Plugin piping

API resource representing a node of the connected acyclic directed graph (DAG) that 
composes a [pipeline](pipeline.md). Each node represents a [plugin](plugin.md) and its 
location within the pipeline's DAG.
A plugin associated to a piping in a pipeline must be of type `ds`.


## Semantic descriptors

* `id`: plugin piping unique identifier
* `plugin_id`: associated plugin's unique identifier
* `plugin_name`: associated plugin's name
* `plugin_version`: associated plugin's version
* `pipeline_id`: associated pipeline's unique identifier


## Link relations

* `plugin`: points to the associated [plugin](plugin.md) 
* `pipeline`: points to the associated [pipeline](pipeline.md)
