# Feed tag

API resource representing a tag applied to a [feed](feed.md). 


## Semantic descriptors

* `id`: feed tag unique identifier
* `name`: feed tag name
* `color`: feed tag color
* `owner_username`: username of the user that owns the tag


## Link relations

* `feeds`: points to the collection of [feeds](feed.md) that has been tagged with the tag
* `taggings`: points to the collection of [tagging](tagging.md) resources that applied 
this tag
