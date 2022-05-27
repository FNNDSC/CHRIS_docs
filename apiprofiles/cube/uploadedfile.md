# User uploaded file

API resource representing a file uploaded by a user to the ChRIS system. 


## Semantic descriptors

* `id`: uploaded file unique identifier
* `creation_date`: file creation date
* `fname`: path of the file in the ChRIS's internal storage (object storage)
* `fsize`: file size in bytes


## Link relations

* `file_resource`: points to the file's contents
* `owner`: points to the user that uploaded the file
