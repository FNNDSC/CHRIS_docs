# Pipelines in ChRIS

## csv as manifest
| patient_id | study_date | modality | accession_number |
|------------|------------|----------|------------------|
| 001        | 2024-01-15 | CT       | ACC12345         |
| 002        | 2024-02-03 | MR       | ACC67890         |

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

## Conclusion
- next steps
- sleep corpus

# 🖥️ Terminal Pipeline Demo

---

## 🚀 Run Pipeline

<p align="center">
<div style="background:#0d1117; border-radius:10px; padding:20px; color:#c9d1d9; font-family:monospace; text-align:left; max-width:900px; margin:auto;">

<span style="color:#7ee787;">➜</span> <span style="color:#79c0ff;">~/project</span> <span style="color:#ff7b72;">git:(main)</span>
$ ./run_pipeline.sh

<br>

<span style="color:#f2cc60;">[LOAD]</span> Reading CSV... <span style="color:#f2cc60;">[PROCESS]</span> Filtering errors... <span style="color:#f2cc60;">[WRITE]</span> Saving output...

<br>

<span style="color:#7ee787;">✔ SUCCESS:</span> Pipeline completed

</div>
</p>

---

## 📂 Inspect Files

<p align="center">
<div style="background:#0d1117; border-radius:10px; padding:20px; color:#c9d1d9; font-family:monospace; text-align:left; max-width:900px; margin:auto;">

<span style="color:#7ee787;">➜</span> <span style="color:#79c0ff;">~/data</span>
$ ls -lh

<br>

-rw-r--r--  data.csv
-rw-r--r--  logs.txt

</div>
</p>

---

## 🔍 Filter Errors

<p align="center">
<div style="background:#0d1117; border-radius:10px; padding:20px; color:#c9d1d9; font-family:monospace; text-align:left; max-width:900px; margin:auto;">

$ grep "error" data.csv

<br>

<span style="color:#ff7b72;">2,Bob,error</span>

</div>
</p>

---

## ⚙️ Python Script

<p align="center">
<div style="background:#0d1117; border-radius:10px; padding:20px; color:#c9d1d9; font-family:monospace; text-align:left; max-width:900px; margin:auto;">

$ python3 process.py

<br>

<span style="color:#f2cc60;">[INFO]</span> Loading data... <span style="color:#f2cc60;">[INFO]</span> Processing... <span style="color:#7ee787;">[SUCCESS]</span> Done

</div>
</p>

---

## 🧠 Pipeline View

<p align="center">
<div style="background:#0d1117; border-radius:10px; padding:30px; color:#c9d1d9; font-family:monospace; text-align:center; max-width:900px; margin:auto; font-size:20px;">

<span style="color:#ff7b72;">[CSV]</span> → <span style="color:#f2cc60;">[QUERY]</span> → <span style="color:#7ee787;">[OUTPUT TABLE]</span>

</div>
</p>

---

## 🎉 Done

<p align="center">
<div style="background:#0d1117; border-radius:10px; padding:20px; color:#c9d1d9; font-family:monospace; text-align:left; max-width:900px; margin:auto;">

$ echo "Done 🚀"

<br>

<span style="color:#7ee787;">Done 🚀</span>

</div>
</p>
