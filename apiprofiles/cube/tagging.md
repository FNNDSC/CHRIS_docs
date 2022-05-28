# Feed tagging

API resource representing an abstract data entity that records the operation of 
"tagging a feed" with an existing [tag](tag.md).


## Semantic descriptors

* `id`: feed tagging unique identifier
* `tag_id`: associated tag's unique identifier
* `feed_id`: associated feed's unique identifier
* `owner_username`: username of the ChRIS user that created the tagging


## Link relations

* `feed`: points to the associated [feed](feed.md)
* `tag`: points to the associated [tag](tag.md)
