# Plugin star

API resource representing an abstract data entity that records the operation of 
"making a plugin a favorite plugin" by a [ChRIS store user](user.md).


## Semantic descriptors

* `id`: plugin star unique identifier
* `plugin_name`: associated plugin's name
* `meta_id`: associated plugin meta's id
* `user_id`: associated user's id
* `username`: associated user's username


## Link relations

* `meta`: points to the associated [plugin meta](pluginmeta.md)
* `user`: points to the associated [ChRIS store user](user.md)
