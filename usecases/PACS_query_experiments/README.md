# Performance Comparison Report: PACS Querying via CUBE API vs PFDCM API

## Objective
The objective of this experiment was to compare the **performance and reliability** of two different approaches for querying a PACS (Picture Archiving and Communication System) — the **CUBE API** and the **pfdcm API** — executed sequentially. The goal was to determine the more efficient and reliable option for large-scale medical imaging data retrieval and analysis within the miniChRIS environment.

---

## Test Setup

| Component        | Configuration                         |
|------------------|----------------------------------------|
| **CUBE Instance** | miniChRIS                             |
| **PACS**         | MINICHRISORTHANC                       |
| **Query Tag**    | `PatientID`                            |
| **Tools Used**   | Python scripts with `requests` and `python-chrisclient` libraries |
| **System Load**  | The pfdcm service was dedicated solely to this test, ensuring no external load or interference during the evaluation. |

---

## Results Summary (Side-by-Side Comparison)

| Metric                     | **PFDCM API** | **CUBE API (requests)** | **CUBE API (chrisclient)** |
|----------------------------|---------------|---------------------|----------------------------|
| Total Requests             | 100           | 100                 | 100                        |
| Successes                  | 100           | 100                 | 100                        |
| Errors                     | 0             | 0                   | 0                          |
| Total Time (seconds)       | 31.52         | 177.65              | 280.18                     |
| Mean Time per Request (s)  | 0.32          | 1.78                | 2.80                       |
| Standard Deviation (s)     | 0.02          | 0.11                | 0.13                       | 

---

## Analysis

### Performance
- The **PFDCM API** significantly outperformed both CUBE API variants.
- The **mean response time** for the PFDCM API was approximately **5.6× faster** than the CUBE API using the `requests` library and **8.9× faster** than the CUBE API using the `chrisclient` library.

### Reliability
- All three methods demonstrated **perfect reliability**, with **100% success** and **0 errors** across 100 requests.

---

## Conclusion

The **PFDCM API** provides the **best performance and consistency** for PACS querying in the tested environment. While the **CUBE API** offers integration convenience, it comes with a significant performance cost.



