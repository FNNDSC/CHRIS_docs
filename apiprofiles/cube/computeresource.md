# Compute resource

API resource representing a computing environment where a ChRIS plugin app can be 
executed.

A compute resource is registered with a CUBE instance by a ChRIS admin before ChRIS 
users can use it to run plugins. It can range in size from a user's personal laptop to a 
massive multi-host Kubernetes cluster. 


## Semantic descriptors

* `id`: compute resource unique identifier
* `creation_date`: creation/registration date
* `modification_date`: modification date
* `name`: compute resource name
* `compute_url`: compute resource's url where plugin jobs are submitted for execution
* `compute_auth_url`: url where auth tokens for the compute resource can be retrieved 
* `description`: compute resource description
* `max_job_exec_seconds`: maximum allowed execution time for a job in seconds


## Link relations