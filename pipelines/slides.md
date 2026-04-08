# Pipelines in ChRIS

## The big picture
[ CSV Spec ]
      ↓
[ PACS Query ]
      ↓
[ PACS Retrieve ]
      ↓
[ Anonymize ]

## csv as manifest
| Search_PatientID | Search_StudyDate | Search_Modality | 
|------------------|------------------|------------------|
| 001              | 20240115         | CT               | 
| 002              | 20240203         | MR               | 

## Different types of pipelines
![Types of pipelines](https://raw.githubusercontent.com/FNNDSC/CHRIS_docs/master/images/types-of-pipelines.png)

## Advantages
- simple
- reproducible
- auditable
- scalable

## Example
<p align="center">
  BLT anonymization workflow
  <img src="https://raw.githubusercontent.com/fnndsc/CHRIS_docs/master/images/BLT-workflow.png" width="5000">
</p>

| Patients | Studies | Series | Instances | Storage Size |
|----------|---------|--------|-----------|---------------|
| 34       | 421     | 7533   | 901759    | 84.71 GB      |

## Next steps
- Collaborators in Toronto
- Sleep Corpus

## Created & edited by
Sandip Samal

