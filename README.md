# Meisler_ReadingInt_DWI
Code and data used in the Meisler, Gabrieli, and Christodoulou 2024 paper on DWI correlates of reading intervention.
To cite:
Meisler, Steven L., John DE Gabrieli, and Joanna A. Christodoulou. "White matter microstructural plasticity associated with educational intervention in reading disability." _Imaging Neuroscience_ (2024).
[![DOI](https://zenodo.org/badge/doi/10.1162/imag_a_00108.svg)](https://doi.org/10.1162/imag_a_00108)

If using code in this study, please note the following:
- You need a FreeSurfer license (register here: https://surfer.nmr.mgh.harvard.edu/registration.html)
- The code assumes a Slurm job scheduler with access to Singularity.
  - The image is `amirro/tracula:latest` https://hub.docker.com/r/amirro/tracula
- Your data must be organized in BIDS, and this code assumes there are `ses-pre` and `ses-post` data
- We cannot share the raw data used in this study, but we share all of the code used to reproduce it, as well as a CSV with necessary data to rerun the statistical analyses
 
### `preproc-code`
First, run the longitudinal `recon-all` pipeline by invoking the job array submission script. In `submit_recon_all_job_array.sh`, change the `bids` variable and add the path to the `recon_all_longitudinal.sh` script in the last line. In `recon_all_longitudinal.sh` update the `scratch` (working direcory) and `fs_img` (container) variables to match your data.

Then, run the longitudinal tracula pipeline by invoking the job array submission script. In `submit_job_array_tracula.sh`, change the `bids` variable and add the path to the `single_subject_tracula.sh` script in the last line. In `single_subject_tracula.sh` update the `IMG` (container), `license` (FS license), and `preproc_dev` (path to `trac-preproc` in this repo) variables to match to your data directory.

### `stats`
In this folder you will find the data frame with necessary subject data as well as a jupyter notebook for running statistical analyses and creating figures. Please refer to comments in the notebook for instructions.

### Questions?
Please open an issue in this repository or email Steven Meisler at smeisler@g.harvard.edu
