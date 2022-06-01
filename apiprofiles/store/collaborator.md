# Plugin collaborator

API resource representing a plugin's collaborator. This is an abstract entity that 
represents a [ChRIS store user](user.md) that has been granted one of the two existing 
roles in maintaining a plugin in the ChRIS store. These roles are owner (O) and 
maintainer (M). 


## Semantic descriptors

* `id`: collaborator unique identifier
* `plugin_name`: associated plugin's name
* `meta_id`: associated plugin meta's id
* `user_id`: associated ChRIS store user's id
* `username`: associated ChRIS store user's
* `role`: collaborator role


## Link relations

* `meta`: points to the associated [plugin meta](pluginmeta.md)
* `user`: points to the associated [ChRIS store user](user.md)
