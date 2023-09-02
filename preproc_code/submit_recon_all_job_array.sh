#!/bin/bash

# Submit subjects to be run through recon-all. Each subject
# will be run as a separate job, but all jobs will share the
# same JOBID, only will differentiate by their array number.
# Example output file: slurm-<JOBID>_<ARRAY>.out

# Usages:
# - specify specific subjects to run:

# bash submit_recon_all_job_array.sh sub-XXX sub-YYY

# - run all subjects in project base:

# bash submit_recon_all_job_array.sh 


subjs=$@

bids=/path/to/bids/root/ # Make this match your path

if [[ $# -eq 0 ]]; then
    # first go to data directory, grab all subjects,
    # and assign to an array
    pushd $fs_dir
    subjs=($(ls sub-* -d))
    popd
fi


# take the length of the array
# this will be useful for indexing later
len=$(expr ${#subjs[@]} - 1) # len - 1

echo Spawning ${#subjs[@]} sub-jobs.

sbatch --array=1-$len /path/to/recon_all_longitudinal.sh $bids ${subjs[@]}
