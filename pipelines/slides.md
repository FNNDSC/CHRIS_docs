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
| patient_id | study_date | modality | accession_number |
|------------|------------|----------|------------------|
| 001        | 2024-01-15 | CT       | ACC12345         |
| 002        | 2024-02-03 | MR       | ACC67890         |

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
<p align="center">
<pre>
$ ./run_pipeline.sh

[LOAD] Reading CSV...
[PROCESS] Filtering errors...
[WRITE] Saving output...

✔ Done.
</pre>
</p>

# 🖥️ Animated Terminal

---

## 🚀 Running Pipeline (Animated)

<p align="center">
<div style="background:#0d1117; border-radius:10px; padding:20px; color:#c9d1d9; font-family:monospace; text-align:left; max-width:900px; margin:auto;">

<pre>

<span class="line1">$ ./run_pipeline.sh</span>
<span class="line2">[LOAD] Reading CSV...</span>
<span class="line3">[PROCESS] Filtering errors...</span>
<span class="line4">[WRITE] Saving output...</span>
<span class="line5">✔ SUCCESS: Done</span>

</pre>

</div>
</p>

<style>
.line1 { opacity: 0; animation: fadeIn 1s forwards 0.5s; }
.line2 { opacity: 0; animation: fadeIn 1s forwards 1.5s; color:#f2cc60; }
.line3 { opacity: 0; animation: fadeIn 1s forwards 2.5s; color:#f2cc60; }
.line4 { opacity: 0; animation: fadeIn 1s forwards 3.5s; color:#f2cc60; }
.line5 { opacity: 0; animation: fadeIn 1s forwards 4.5s; color:#7ee787; }

@keyframes fadeIn {
  to { opacity: 1; }
}
</style>

---

## ⌨️ Typing Effect

<p align="center">
<div style="background:#0d1117; border-radius:10px; padding:20px; color:#c9d1d9; font-family:monospace; max-width:900px; margin:auto;">

<pre>
<span class="typing">$ echo "Hello World"</span>
</pre>

</div>
</p>

<style>
.typing {
  border-right: 2px solid #c9d1d9;
  white-space: nowrap;
  overflow: hidden;
  display: inline-block;
  width: 0;
  animation: typing 3s steps(20, end) forwards, blink 0.7s infinite;
}

@keyframes typing {
  to { width: 22ch; }
}

@keyframes blink {
  50% { border-color: transparent; }
}
</style>

---

## 🧠 Animated Pipeline

<p align="center">
<div style="background:#0d1117; border-radius:10px; padding:30px; font-family:monospace; text-align:center; max-width:900px; margin:auto; font-size:22px;">

<span class="p1">[CSV]</span> → <span class="p2">[QUERY]</span> → <span class="p3">[OUTPUT]</span>

</div>
</p>

<style>
.p1 { opacity:0; animation: fadeIn 1s forwards 0.5s; color:#ff7b72; }
.p2 { opacity:0; animation: fadeIn 1s forwards 2s; color:#f2cc60; }
.p3 { opacity:0; animation: fadeIn 1s forwards 3.5s; color:#7ee787; }
</style>
## 📄 Animated CSV in Terminal

<p align="center">
<div style="background:#0d1117; border-radius:10px; padding:20px; color:#c9d1d9; font-family:monospace; text-align:left; max-width:1000px; margin:auto;">

<pre>
<span class="cmd">$ cat sample.csv</span>

<span class="h">patient_id | study_date | modality | accession_number</span>
<span class="h">-----------+------------+----------+------------------</span>
<span class="r1">001        | 2024-01-15 | CT       | ACC12345</span>
<span class="r2">002        | 2024-02-03 | MR       | ACC67890</span>
</pre>

</div>
</p>

<style>
.cmd { color:#7ee787; opacity:0; animation: fadeIn 1s forwards 0.5s; }

.h { color:#79c0ff; opacity:0; animation: fadeIn 1s forwards 1.5s; }

.r1 { opacity:0; animation: fadeIn 1s forwards 3s; }
.r2 { opacity:0; animation: fadeIn 1s forwards 4.5s; }

@keyframes fadeIn {
  to { opacity: 1; }
}
</style>

