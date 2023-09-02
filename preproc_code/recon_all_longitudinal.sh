#!/bin/bash
#SBATCH --time=44:00:00
#SBATCH --mem=16GB
#SBATCH --cpus-per-task=16
#SBATCH -J recon-all-long

# Add singularity to the path
module add openmind/singularity/3.9.5

# Singularity image file paths
fs_img=/path/to/freesurfer_image.img # REPLACE WITH YOUR OWN IMAGE

# Do not stop on errors
set -eu

# assign BIDS directory and output
bids_dir=$1
output_dir=${bids_dir}/derivatives/tracula/freesurfer/
mkdir -p $output_dir

# Get subject name from job array
args=($@)
subjs=(${args[@]:1})
subject=${subjs[${SLURM_ARRAY_TASK_ID}]}

#Get list of sessions
declare -a sessions=("ses-pre" "ses-post")
# Make sure subject has pre and post data
for ses in ${sessions[@]}; do
if [ ! -e ${bids_dir}/$subject/$ses/anat/${subject}_${ses}_T1w.nii.gz ];
then echo "SUBJECT MISSING DATA FOR SESSION $ses"; exit
fi
done

# assign and prepare working directory
scratch=/path/to/scratch/directory/${subject} # REPLACE WITH YOUR OWN PATH
mkdir -p $scratch
# make sure FreeSurfer operates in scratch
export SINGULARITYENV_SUBJECTS_DIR=$scratch

# Remove temporary FreeSurfer files
rm -f $scratch/*/scripts/*Running*

######## RUN EACH SESSION INDIVIDUALLY IN PARALLEL #######
# move files to scratch and run recon-all
for ses in ${sessions[@]}; do
cp -n ${bids_dir}/$subject/$ses/anat/${subject}_${ses}_T1w.nii.gz $scratch
# If recon-all already started, continue, if not start anew
if [ -d $scratch/${subject}_${ses} ]; then
singularity exec -e -B $scratch -B $bids_dir/code/tracula/license.txt:/usr/local/freesurfer/.license $fs_img recon-all -subjid ${subject}_${ses} -all &
else
singularity exec -e -B $scratch -B $bids_dir/code/tracula/license.txt:/usr/local/freesurfer/.license $fs_img recon-all -subjid ${subject}_${ses} -all -i $scratch/${subject}_${ses}_T1w.nii.gz &
fi
done
wait # wait for both sessions to finish before continuing
# Move outputs to output directory
cp -rn $scratch/${subject}_* ${output_dir}/

######## MAKE THE SUBJECT TEMPLATE #######
singularity exec -e -B $scratch -B $bids_dir/code/tracula/license.txt:/usr/local/freesurfer/.license $fs_img recon-all -base ${subject} \
 -tp ${subject}_ses-pre -tp ${subject}_ses-post -all
cp -rn $scratch/${subject} ${output_dir}/

######## RUN THE LONGITUDINAL STREAM #######
singularity exec -e -B $scratch -B $bids_dir/code/tracula/license.txt:/usr/local/freesurfer/.license $fs_img recon-all -long ${subject}_ses-pre ${subject} -all &
singularity exec -e -B $scratch -B $bids_dir/code/tracula/license.txt:/usr/local/freesurfer/.license $fs_img recon-all -long ${subject}_ses-post ${subject} -all &
wait
cp -rn $scratch/${subject}_*.long.${subject} ${output_dir}/

echo "DONE!"

