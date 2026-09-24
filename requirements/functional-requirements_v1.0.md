# ChRIS Functional Requirements for 1.0 Release

## A. Login
- [ ] 01. Users must be able to log in using BCH LDAP on internal BCH deployment

## B. PACS
- [ ] 01. BCH PACS is available on internal BCH deployment
- [ ] 02. Anonymous data orthanc is available external/public deployment
- [ ] 03. User can pull image to ChRIS from PACS
- [ ] 04. User can launch "create new analysis" wizard from a series in a PACS search result(see related req #G03)
- [ ] 05. User can view studies & series organized hierarchically by patient
- [ ] 06. User can preview image data in a series from a PACS search result
- [ ] 07. User can search PACS via single patient ID or MRN
- [ ] 08. User can search PACS via single Patient Name
- [ ] 09. User can search PACS via single accession number
- [ ] 10. User can filter PACS results by any or all of the following: study date, modality, station title, patient birth date

## C. Overview
- [ ] 01. New user with no data or analyses will see new user overview
- [ ] 02. New user with data but no analyses will see overview page with "no analyses" card + "you have data" card
- [ ] 03. User with data and analyses will see overview page with "you have data" + "you have analyses" cards

## D. My Library
- [ ] 01. User can upload a file into "My Library" from local system
- [ ] 02. User can view analyses data output from "My Library"
- [ ] 03. User can access previous PACS pulls from "My Library"
- [ ] 04. User can search library for a single filename (wildcards?)
- [ ] 05. User can search library for a single patient name (wildcards?)
- [ ] 06. User can search library for a single MRN (wildcards?)
- [ ] 07. User can search library for file modality (wildcards?)
- [ ] 08. User can search library for analysis ID / analysis name (wildcards?)

## E. My Analyses
- [ ] 01. User can view a list of previous analyses they ran from their account
- [ ] 02. User can view a catalog of analysis types
- [ ] 03. User can launch a new analysis from catalog of analysis types (see related req #G04)
- [ ] 04. User can access analysis template JSON they uploaded in the analysis catalog

## F. Create New Analyses Wizard
- [ ] 01. ("Templated analysis") User can create a new analysis, choosing which data and which analysis [pipeline] to run
- [ ] 02. ("Ad-hoc analysis") User can create a new analysis, choosing which data and adding plugins to the analysis ad-hoc 
- [ ] 03. User can navigate to data in their library, and launch the create new analysis wizard from their selection in order to have the data they selected pre-populated into the wizard, and manually select the analysis to run (whether templated or ad-hoc)
- [ ] 04. User can navigate to an analysis type in the analysis catalog, and launch the create new analysis wizard from their selection in order to have the analysis type they selected pre-populated in the wizard, and manually select the data to analyze
- [ ] 05. There will be one unified analysis creation wizard tool (instead of two)
- [ ] 06. User can upload a JSON formatted analysis template to create an analysis

## G. Visualize
- [ ] 01. User will be able to drag 'n drop or upload files to a DICOM viewer to view them (supported types?)
