# Plugin meta

API resource representing meta data that applies to all versions of a [plugin](plugin.md). 

A plugin meta resource is automatically created when a ChRIS admin registers the first 
version of a plugin with a CUBE instance. Then it's referenced by all subsequent 
versions of the plugin. Some of the attributes of a plugin meta can be modified after 
initial creation and the change is reflected across all the plugin versions.


## Semantic descriptors

* `id`: plugin meta unique identifier
* `creation_date`: creation/registration date
* `modification_date`: modification date
* `name`: plugin name
* `title`: plugin title
* `stars`: number of users that has made the plugin a favorite plugin 
* `public_repo`: url of the source control repo for the plugin's source code 
* `license`: plugin release license 
* `type`: plugin type which can be one of `ds`, `fs` or `ts` 
* `icon`: url of an icon image for the plugin
* `category`: plugin category
* `authors`: string representing a comma separated list of author emails
* `documentation`: url of a website or wiki page containing documentation about the 
  plugin


## Link relations

* `plugins`: points to the collection of related [plugins](plugin.md) (versions of the 
  same plugin) 
