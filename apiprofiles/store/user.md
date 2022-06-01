# ChRIS store user

API resource representing a ChRIS store's authenticated user. 


## Semantic descriptors

* `id`: ChRIS user unique identifier
* `username`: ChRIS user username
* `email`: ChRIS user email


## Link relations

* `favorite_plugin_metas`: points to the collection of the user's favorite 
 [plugin metas](pluginmeta.md)
* `collab_plugin_metas`: points to the collection of the [plugin metas](pluginmeta.md) for
 which the user is a collaborator
