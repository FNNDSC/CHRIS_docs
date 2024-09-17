``LLD analysis of Leg Images``

``` List of plugins used```
1) pl-dylld
2) pl-shexec
3) pl-dcm2mha
4) pl-csv2json
5) pl-lld_inference
6) pl-topologicalcopy
7) pl-markimg
8) pl-dicommake
9) pl-lld_chxr
10) pl-neurofiles-push
11) pl-dicom_dirsend

```Analysis tree```

```mermaid
   stateDiagram-v2
    dircopy --> unstack_folders: flatten directory structure
    unstack_folders --> dylld: dynamically create the LLD workflow on input
    unstack_folders --> shexec: copy input to output directory
    shexec --> dcm2mha_cnvtr: convert the input DICOMs to mha
    state topologicalcopy1 <<join>>
    state topologicalcopy2 <<join>>
    state topologicalcopy3 <<join>>
    shexec --> topologicalcopy2
    topologicalcopy2 --> csv2json
    topologicalcopy2 --> topologicalcopy3
    topologicalcopy3 --> lld_chxr
    lld_chxr --> dicommake
    lld_chxr --> neurofiles_push2
    dicommake --> dicom_dirsend
    csv2json --> topologicalcopy1
    dcm2mha_cnvtr --> lld_inference
    lld_inference --> topologicalcopy1
    lld_inference --> topologicalcopy2
    topologicalcopy1 --> markimg
    markimg --> neurofiles_push1
    markimg --> topologicalcopy3
    
```