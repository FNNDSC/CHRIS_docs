# Plugin instance

API resource representing a run of a [plugin](plugin.md) on the ChRIS platform. It is 
scheduled as a one-off job on a [compute resource](computeresource.md) associated with the
plugin by the ChRIS admin. A plugin instance of a [plugin](plugin.md) of type FS (feed 
synthesis plugin) also creates a new [feed](feed.md) in the ChRIS system.

## Semantic descriptors

* `id`: plugin instance unique identifier
* `title`: plugin instance title
* `creation_date`: creation/registration date
* `compute_resource_name`: name of the [compute resource](computeresource.md) where 
  the plugin instance was executed
* `plugin_id`: related plugin id
* `plugin_name`: related plugin name
* `plugin_version`: related plugin version
* `plugin_type`: related plugin type
* `license`: plugin release license 
* `type`: plugin type which can be one of `ds`, `fs` or `ts` 
* `icon`: url of an icon image for the plugin
* `category`: plugin category
* `authors`: string representing a comma separated list of author emails
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

* `feed`: points to the [feed](feed.md) containing the plugin instance
* `plugin`: points to the plugin instance's [plugin](plugin.md) 
* `descendants`: points to the collection of descendant plugin instances
* `files`: points to the collection of plugin instance files created by the plugin 
  instance
* `parameters`: points to the collection of plugin's command line parameter values used 
to create the plugin instance
* `compute_resource`: points to the [compute resource](computeresource.md) where the 
  plugin instance was run
* `splits`: points to the collection of splits performed on the plugin instance
