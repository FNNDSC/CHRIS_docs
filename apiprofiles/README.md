# Profile documents for ChRIS's Web APIs 


## Abstract

These directories of the ChRIS docs contain profile documents for the ChRIS platform's 
Web APIs.

In the context of a Web API a profile document is usually a human-readable documentation 
of the application semantics of the resource representations provided by the particular 
API. It's basically a free-form explanation of the real world entities and concepts that 
the API's resources are modeling.

Both the ChRIS web server (CUBE) and the ChRIS store web server's APIs are 
hypermedia-based Rest APIs since they use the 
[Collection+JSON](http://amundsen.com/media-types/collection/) standard and its 
hypermedia capabilities to exchange resource representations with clients.

All the resources provided by the APIs can be discovered by clients by making GET 
requests to links (“href” elements) presented by the hypermedia documents returned 
by the web server.

For a hypermedia-based API the semantics of the API can be divided into two categories:

1. semantic descriptors (properties/fields returned in a resource representation)
2. link relations (string names attached to hypermedia controls such as the “href” 
   elements)


## ChRIS web server (CUBE)'s Rest API profile

[Available here](cube/README.md)
 

## ChRIS store web server's Rest API profile

[Available here](store/README.md)