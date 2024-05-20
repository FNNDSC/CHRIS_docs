# Plugins and Registration in CUBE
# Chapter 3 -- Registration using a GUI and a store 

## Abstract

This document is part three of the _Plugins and Registration in CUBE_ series. It explores the current experience of registering a plugin using only supplied UIs and assuming an intent to register a plugin listed on app.chrisproject.org with quantification of this experience against the **Ground Truth** reference of Chapter 1.

The document will quantify somewhat the user experience complexity, and offer possible solutions that can bring this experience much closer to the **Ground Truth**.

# Task 1 -- register a plugin from the GUI using a "store"

As initial condition, assume the reference ChRIS UI is open the `Plugins` tab of app.chrisproject.org and a target plugin to install is [visible](https://app.chrisproject.org/plugin/100). We notice the "Copy and Paste the URL below into your ChRIS Admin Dashboard to install this plugin" with a link and a "copy-to-browser" button. All four of our users will have the identical experience since only one approach is possible.

At this stage, the experience is functionally equivalent to the Desktop comparison, as there are no Implicit Preconditions and the let us assume the Required Preconditions are met (since the ChRIS UI satisfies all these at this juncture).

## First Hurdle

### Where is the "ChRIS Admin Dashboard"?

The GUI and context we are in provides no indication of what this "ChRIS Admin Dashboard" is or where to find it, even though it is almost always at the same regular location relative to the GUI URL itself. In fact, new users at this point will most likely assume this Dashboard is somewhere in the ChRIS UI and could spend an ultimatley frustrating amount of time doing fruitless exploration.

From the user perspective at this point, there is simply no reason to have this obscured, particularly since the Admin Dashboard is password protected. From a _design perspective_ this violates the Locality of Behavior principle. Simply, if a _next_ behavior is obvious or implied in a context, then every should be made to provide this behavior in that context.

At this point, a user now:

* might perform a google search for:
  * "ChRIS Admin Dashboard"
  * "How I install a plugin"
  * maybe know that there is chrisproject.org and maybe poke around there?
* simply give up

#### Hidden first-time context switch

* determine location of ChRIS Admin Dashboard

None of this should be something a user has to somehow resolve independently of the intent of simply wanting to install this plugin. Moreso if the plugin is "visible" by the ChRIS UI in the "store". This first massive context switch could be an insurmountable barrier. Also, a local CUBE user might not have any idea about the app.chrisproject.org plugin "store", which itself suggests a current design oversight.

### Once the Dashboard is known -- steps and context switches to access from ChRIS UI

Let's assume now that the user knows where their local Dashboard for their local CUBE is located. This is an _implicit precondition_. Let us tabulate the steps and context switches needed to perform the simple intent of "install this plugin" if a user has gone to the effort of finding this on the app.chrisproject.org plugin detail page:

#### Steps

* click on the app.chrisproject.org copy icon;
* open a new tab;
* type (or from bookmark navigate to) the ChRIS Admin Dashboard URL of the local CUBE;
* at the login screen, enter admin credentials

#### Context switches

* ChRIS UI to Dashboard UI

### Perform the actual registration

Now, in the Dashboard UI:

* Click "Plugins +Add"
* Click in the text input field for the "Or identify plugin by url"
* Middle-click (or right-click choose Paste) to drop the URL
* Click SAVE

(Let us assume for more fair comparisons that the default behavior is to register to all compute resources, since there is no equivalent desktop analog thus we disregard these addition ChRIS-only steps.)


## Task 1 -- desktop _cf._ ChRIS/CUBE UI

| Technique                     | Implicit Precon | Required Precon | Steps  | Complexity | Bulk cost    | Context Switch |
| -----------------             |:--------------: | :-------------: | :----: | :--------: | :---------:  | :------------: |
| Desktop app install from web  | 0               |  3              | 3      |  0         |  _high_      | 0              |
| ChRIS plugin install from web | 1               |  3              | 8      |  2         |  _high_      | 1              |

The assignment of _2_ for complexity is somewhat subjective, but is a measure of the context switching, the completely different Dashboard UI, and the number of steps required.

## Fairness of comparison

There is some unfairness in this experiment since the desktop experience has the user explicitly access a store which explicitly is external to their computer. Currently in ChRIS, if you are in a local ChRIS UI you cannot browse a remote store. You in fact have to "visit" that store (other ChRIS) in a new browser tab to determine its wares. Since the local and remote are the same apparent UI, it can be confusing as to which is which.


## Solution proposal

From a _user_ and _operational_ perspective there would seem to be no technical reason for this experience to be so cumbersome. None of the current steps increase the security of CUBE nor provide additional checks or assurances on the safety or behavior of plugin to be registered. They simply make the experience _harder_.

In order to bring the current ChRIS experience closer to the desktop experience, the following are proposed for consideration:

### Explicit Store tab in the ChRIS UI 

Given that app.chrisproject.org is the _de facto_ world wide reference Store for ChRIS plugins, the ChRIS UI could offer a dedicated "Store" tab that simply accesses the public app.chrisproject.org plugin space. It could be suggested that this Store is styled slightly differently to the local Plugin tab to aid in differentiation.

Within this "Store" experience, the ChRIS UI could offer a "Register this plugin" as a slight variation on the "Copy and Paste the URL...". When "clicked", the ChRIS UI can use a modal to capture the administrator credentials of the local CUBE, and then perform the registration itself. This assumes that the Django admin backend is amenable to this or can be driven by a client-side library in javascript.

## Solution prerequisites

The following are pertinent:

* can the Django admin backend be accessed by an API?
* if not, could a separate plugin registration microservice be meaningful?




