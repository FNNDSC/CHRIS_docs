# Service file

API resource representing a file uploaded to the ChRIS system by a general service with 
access to ChRIS's internal storage. 


## Semantic descriptors

* `id`: service file unique identifier
* `creation_date`: file creation date
* `fname`: path of the file in the ChRIS's internal storage (object storage)
* `fsize`: file size in bytes
* `service_name`: service name
* `service_identifier`: service unique identifier within the ChRIS system 


## Link relations

* `file_resource`: points to the file's contents
