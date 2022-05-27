# PACS file

API resource representing a DICOM file uploaded to the ChRIS system by a service
(typically ChRIS's `pfdcm`) with access to ChRIS's internal storage and that interacts 
with a PACS (Picture Archiving and Communication System). 


## Semantic descriptors

* `id`: PACS file unique identifier
* `creation_date`: file creation date
* `fname`: path of the file in the ChRIS's internal storage (object storage)
* `fsize`: file size in bytes
* `PatientID`: patient unique identifier recorded in the DICOM file 
* `PatientName`: patient name recorded in the DICOM file 
* `PatientBirthDate`: patient birth date recorded in the DICOM file 
* `PatientAge`: patient age at the time of the imaging session recorded in the DICOM file 
* `PatientSex`: patient sex recorded in the DICOM file 
* `StudyDate`: patient study date recorded in the DICOM file 
* `AccessionNumber`: accession number recorded in the DICOM file 
* `Modality`: file's image modality recorded in the DICOM file 
* `ProtocolName`: imaging protocol name recorded in the DICOM file
* `StudyInstanceUID`: study unique identifier recorded in the DICOM file 
* `StudyDescription`: study description recorded in the DICOM file 
* `SeriesInstanceUID`: series unique identifier recorded in the DICOM file
* `SeriesDescription`: series description recorded in the DICOM file
* `pacs_identifier`: PACS unique identifier within the ChRIS system 


## Link relations

* `file_resource`: points to the file's contents
