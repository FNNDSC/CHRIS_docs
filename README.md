# ChRIS

## Abstract
This page presents a quick overview to ChRIS, followed by some links to more resources, papers, and talks.

## Overview
ChRIS (**Ch**RIS **R**esearch **I**ntegration **S**ervice) is a novel and opensource software platform designed to manage and coordinate computation and data on a multitude of computing environments, from laptops to loosely connected groups of workstations, to high performance compute clusters, to public clouds.

ChRIS is designed to manage the execution and data needs of a typical class of computational applications often used in research settings. **These are applications that require no user interaction once started** and typically initialize from a setup-data-state, have runtime specifications typically passed in command line arguments, and collect all output in files. 

While ChRIS itself has a web-based user interface, the applications (or plugins as they are also called) that perform the computations, do not have graphical user interfaces but are command line, containerized, Linux-based applications.

ChRIS comprises a collection of REST-based web services, backend web apps, and various client-facing web front ends. The system is designed to make it as *easy* as possible for a developer to get his/her app running *anywhere* (computing environments). By conforming to a reasonable command-line standard for ChRIS applications, ChRIS makes it easy to dockerize and then run the research software

## Need

Computational research in scientific (as opposed to industry) medical-related fields faces many obstacles, including (but 
not limited to):

* data sharing
* data protection
* data visualization
* algorithm/program sharing
* re-use of existing programs in different environment
* access to powerful hardware
* realtime collaboration

## Existing solutions

Cloud resources are available from private and public companies -- Amazon, Microsoft, Google, etc. In many contexts, these resources are geared to web-based service provision and not ideal for running commonly found apps in scientific research that simply crunch data and create an output.

Not only is there a cost involved to using these services, but the barrier to entry is arguably quite high. In addition there is always the vendor-locking problem that makes it difficult to migrate data not only between different cloud providers but to the user-owned facilities. Running a simple app that takes an input and creates an output often requires complex setup and re-thinking of how the app can fit within a generalized web-services computational model.

Finally, none of the mentioned services allow an end user to re-create that cloud locally for development / debugging. An end user cannot download a "mini-AWS" and run on their local hardware, for example.

## Enter ChRIS

ChRIS exists as a public github repo and can be downloaded and instantiated with a few commands. On a local computer, this will download all the necessary services and provide a fully working system that is ready to service client commands.

With some minor additional work, specific micro-services can be instantiated on different computers, and ChRIS can coordinate data and compute between all these computers.

## Quick deep dive -- backend

The main backend engine of ChRIS, called CUBE (ChRIS Ultron Back-End) is a python django app that provides databasing and services through a REST API that uses the standard [Collection+JSON](http://amundsen.com/media-types/collection/) hypermedia type to exchange resource representations with clients.

CUBE in turn "talks" to a coordinating service called ``pfcon``, which  is the dispatching service between CUBE and an actual computational environment. In this environment, two additional services are required to exist and be http accessible: ``pman`` that does process management, and ``pfioh`` that handles data IO.

A companion client app called ``pfurl`` can be used to communicate with all of these services.

## Quick deep dive -- frontend

There are many possible front-ends to ChRIS. In fact, any program that consumes the ChRIS REST API can construct a tailor made experience.

An official front end is currently in active development, see the talk links for more info.

Visualization of medical formatted image data is provided by two projects that have been developed in-house

* xtk 
* ami

## Recent Papers

Some papers and conference proceedings on ChRIS -- please note in some papers the system is called *CHIPS*:

* Rudolph Pienaar, Ata Turk, Jorge L. Bernal-Rusiel, Nicolas Rannou, Daniel. Haehn, Steve Pieper, Patricia E. Grant, and Orran Krieger. “[CHIPS – A Service for Collecting, Organizing, Processing, and Sharing Medical Image Data in the Cloud.](https://github.com/FNNDSC/CHRIS_docs/blob/master/papers/LNCS_VLDB_Healthcare.pdf)” In: Lecture Notes in Computer Science, Vol. 10494, pp. 29–35, 2017.

* Rudolph Pienaar, Jorge L. Bernal-Rusiel, Nicolas Rannou, Daniel Haehn, Patricia E. Grant, Ata Turk, and Orran Krieger. “[Architecting and Building the Future of Healthcare Informatics: Cloud, Containers, Big Data and CHIPS.](https://github.com/FNNDSC/CHRIS_docs/blob/master/papers/FTC_2017_IEEE_Conference.pdf)” In: IEEE Future Technologies, 2017.

* Bernal-Rusiel, Jorge L., Nicolas Rannou, Randy L. Gollub, Steve Pieper, Shawn Murphy, Richard Robertson, Patricia E. Grant, and Rudolph Pienaar. “[Reusable Client-Side JavaScript Modules for Immersive Web-Based Real-Time Collaborative Neuroimage Visualization.](https://github.com/FNNDSC/CHRIS_docs/blob/master/papers/fninf-11-00032.pdf)” In: Frontiers in neuroinformatics 11, p. 32, 2017.

* R Pienaar, N Rannou, J Bernal-Rusiel, D Haehn, and P E Grant. “[ChRIS – A Web-Based NeuroImaging and Informatics System for Collecting, Organizing, Processing, Visualizing, and Sharing of Medical Data](https://github.com/FNNDSC/CHRIS_docs/blob/master/papers/EMBS_ChRIS_IEEE_Conference.pdf)”. In: IEEE Engineering in Medicine and Biology Magazine.

* Nicolas Rannou, Jorge Luis Bernal-Rusiel, Daniel Haehn, Patricia Ellen Grant, Rudolph Pienaar, "[Medical imaging in the browser with the A* Medical Imaging (AMI) toolkit.](https://github.com/FNNDSC/CHRIS_docs/blob/master/papers/esmrmb2017.7403b23.NORMAL.pdf)", European Society for Magnetic Resonance in Medicine and Biology 2017.


## Recent Talks

Some recent talks on ChRIS (please note there is much recycling on content below! I've added a quick note to the time length as a partial guide):

[National Alliance for Medical Compting, NA-MIC, Jan 2018 Project week talk (30 minutues)](http://slides.com/debio/deck-6-7-8-12-13-19-22)

[Massachusetts Open Cloud (5 minutes)](http://slides.com/debio/deck-6-7-8-12-13-19)

## Programming Links

Links to ChRIS components:

