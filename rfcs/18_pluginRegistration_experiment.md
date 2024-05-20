# Plugins and Registration in CUBE 
# Chapter 1 -- Introduction and Overview

## Abstract

The core of ChRIS is a system called **CUBE** (ChRIS Underlying Backend) that is responsible (among many things) of running applications called _plugins_. In order to run a _plugin_, it must be _registered_ to a CUBE. The actual mechanics of this operation are not important here. What is important is that two fundamental prerequisites are required:

* 1 - some information about the plugin itself, and
* 2 - credentials to register the plugin.

This document is part of a family of documents exploring this problem. Here we discuss the problem, offer several ground truth domains for measurement, and suggest a matrix for measuring behaviour. Other documents present various hypothetical users, and consider how each ground truth domain measures against users and intentions. Each detailed expose will highlight deficiencies in the currend model, and propose ultimately solutions that can address this within that domain context.

# Introduction

According to the official [documentation](https://chrisproject.org/docs/tutorials/upload_plugin), five techniques are available for registering a plugin:

* the Django Dashboard;
* the core CUBE API;
* chrisomatic;
* automatic upload via github actions;
* non-canonical scripts like `plugin2cube`

Each of these methods can be used. Each has more applicable use cases, depending on a given need, but as we will argue, each is deficient across a set of measurement metrics, such that the overall experience is degraded. Moreover, this degraded experience is not _endemic_, but the result of legacy and lethargy. While CUBE is a web/cloud application and not a desktop computer, the experience of installing plugins can be brought much closer to desktop simplicity.

We believe this will further improve/benefit the entire project.

# Ground truth

Let us assume that most users of ChRIS/CUBE have used a computer and installed software on that computer. As with CUBE, two fundamental pieces of information are needed:

* the application to install (or information on this application);
* appropriate credentials

On a desktop operating system, installation can be effected either with a GUI or from the CLI. Both these will form the ground truth. We might argue that a desktop comparison is unfair in the context of CUBE, since the latter is web-based system. However, CUBE provides an _experience_ that is desktop-like in both its GUI and prototypical CLI experiences. Moreover, users will come with a desktop background and attempting to measure the delta between these experiences is meaningful.

Ultimately we hope to show that several CUBE plugin registration experiences can be _identical_ to desktop application install.

# Measurement space

Let us now consider against what metrics we wish to measure our experiences. As a baseline, assume that basic setup has been performed. In the case of CUBE, this means a local installation of a _barebones_  CUBE with attendant supporting infrastructure (like `docker` or `podman`).

* **implicit preconditions** -- the amount of pre-requisites required that need to be satisfied before a registration technique can even be attempted -- this is meant to measure _additional_ needs that are not part of the default environment a user has -- for example tools such as `curl`;
* **required preconditions** -- the amount of pre-requisites to get required information for a registration;
* **steps** the number of steps required once the preconditions are met (this can include mouse clicks on a GUI);
* **complexity** of the steps -- while this is a subjective measure, most readers will agree with the perception of _complexity_ for executing a task. For instance a single CLI command that requires many components and cognitive load is more complex than a command that requires less. Let us thus define "complexity" for a CLI activity as the number of additional pieces of information need beyond the plugin (name) to install and the superuser credentials;
* **bulk** -- ease of bulk actions;
* **context switches** -- a context switch is when a user is in one "environment" and needs to switch to a completely different environment while performing a single task

# Ground truth reference

We will consider four ground truth comparison domains on a conventional desktop OS:

* GUI from a "store"
* GUI from local "download"
* CLI from a repository
* CLI from local


| Technique        | Implicit Precon | Required Precon | Steps  | Complexity | Bulk cost    | Context Switch |
| -----------------|:--------------: | :-------------: | :----: | :--------: | :---------:  | :------------: |
| GUI from a store | 0               |  3              | 3      |  0         |  _high_      | 0              |
| GUI from download| 0               |  3              | 3      |  0         |  _high_      | 0              |
| CLI from repo    | 0               |  3              | 2      |  1         | _low_        | 0              |
| CLI from local   | 0               |  3              | 2      |  2         | _low_        | 0              |

On a local computer, the _implicit preconditions_ can be assumed already met. These include bundled tools (like a file system browser to select files to install) a web browser to access on online store.

The _required preconditions_ are knowledge of the application to install, superuser credentials, and knowledge either of the command line app to use or knowledge of how to navigate to the store from the UI.

_Steps_ is a more subjective measure, but in the case of the GUI attempts, this is counted as, "Assuming the browser or file explorer is showing the target to install" then the _steps_ are:

* 1 -- click on the object to install
* 2 -- a credentialing dialog box opens
* 3 -- type in credentials

In the case of the CLI, the _Steps_ are:

* 1 -- type in (and enter) the CLI to install the application
* 2 -- type in superuser credentials

_Complexity_ is taken to mean, assuming knowledge of the application to install (its name for example) how _hard_ is the operation. Here, the GUIs are assumed to be simplest since if the GUI is showing (or focused on) the application to install, the following complexity of experience is _expected to be_ trivial. For the CLI, installation from a repo can be implemented by accessing a terminal and typing one command; while a local installation requires some knowledge of where on the file system the application installer is located, navigating there, and typing an installation command.

_Context switches_ are known to be anathema to productivity and workflows. Aspiring to minimize these should always be a high priority. The start context here is assumed to the starting environment in which a registration is about to be performed (so this could be web UI already open on say `app.chrisproject.org` or a terminal already open for CLI work). A context switch is here taken to any new/different/unrelated switch (even within the same domain -- e.g. GUI or CLI) needed to perform one single task.

# Next Reading

The next document to read is the overview of four different users, each has the same need/intention: register a plugin to a CUBE over which they have full control. Additional documents will explore each of the 4 ground truth domains.

