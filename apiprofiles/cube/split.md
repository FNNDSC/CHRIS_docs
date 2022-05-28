# Plugin instance split

API resource representing an abstract data entity that records the topological 
operation of "splitting a plugin instance's output directory". This operation consists in 
creating one or more `pl-topologicalcopy` plugin instances from the same input directory 
which is the output directory of the split plugin instance. The output directory of each 
newly created plugin instance contains the files in their input directory that match a 
regular expression filter pre-specified for each new plugin instance as a parameter of 
the split operation.


## Semantic descriptors

* `id`: split unique identifier
* `creation_date`: split creation date
* `filter`: string representing a comma-separated list of regular expressions, one per 
  each newly created plugin instance
* `created_plugin_inst_ids`: string representing a comma-separated list of IDs, one per 
  each newly created plugin instance
* `plugin_inst_id`: id of the split plugin instance 


## Link relations

* `plugin_inst`: points to the split [plugin instance](plugininstance.md) 
