#!/bin/bash
#SBATCH --time=2-00:00:00
#SBATCH --mem=32GB
#SBATCH --cpus-per-task=24
#SBATCH -J ss_tracula

IMG=/path/to/freesurfer_container.img # Make this match your path

# Add singularity
module add openmind/singularity/3.9.5

# Do not stop on errors
set -eu

# Get subject name from job array
args=($@)
subjs=(${args[@]:1})
subject=${subjs[${SLURM_ARRAY_TASK_ID}]}
sub=${subject:0:12}

echo "SUBJECT: ${sub}"

# Define important paths
BIDS=$1
trdir=${BIDS}/derivatives/tracula/tracts # tracula directory
license=${BIDS}/code/tracula/license.txt # FS license, make this match your data
preproc_dev=${BIDS}/code/tracula/trac-preproc

scratch=/om2/scratch/Fri/$(whoami)/START_tracula
mkdir -p $scratch

rm -f ${trdir}/${sub}*/scripts/*Running*

n_vols=73 # number of volumes in DWI image

# Singularity command convenience wrapper
fs="singularity exec -e -B $scratch -B ${BIDS} -B ${license}:/usr/local/freesurfer/.license -B ${preproc_dev}:/opt/freesurfer/bin/trac-preproc $IMG"

# Preproc
echo "BEGINNING PREPROC"

$fs trac-preproc -c ${trdir}/${sub}_ses-post.long.${sub}/scripts/dmrirc.local -log ${trdir}/${sub}_ses-post.long.${sub}/scripts/trac-all.log -cmd ${trdir}/${sub}_ses-post.long.${sub}/scripts/trac-all.cmd &

$fs trac-preproc -c ${trdir}/${sub}_ses-pre.long.${sub}/scripts/dmrirc.local -log ${trdir}/${sub}_ses-pre.long.${sub}/scripts/trac-all.log -cmd ${trdir}/${sub}_ses-pre.long.${sub}/scripts/trac-all.cmd &

wait

$fs trac-preproc -c ${trdir}/${sub}/scripts/dmrirc.local -log ${trdir}/${sub}/scripts/trac-all.log -cmd ${trdir}/${sub}/scripts/trac-all.cmd

# Bedpost
echo "BEGINNING BEDPOSTX"
mkdir -p ${trdir}/${sub}_ses-post.long.${sub}/dmri.bedpostX/logs/monitor
mkdir -p ${trdir}/${sub}_ses-pre.long.${sub}/dmri.bedpostX/logs/monitor
ln -sf ${trdir}/${sub}_ses-pre.long.${sub}/dmri/lowb_orig_las_brain_mask.nii.gz ${trdir}/${sub}_ses-pre.long.${sub}/dmri/nodif_brain_mask.nii.gz
ln -sf ${trdir}/${sub}_ses-post.long.${sub}/dmri/lowb_orig_las_brain_mask.nii.gz ${trdir}/${sub}_ses-post.long.${sub}/dmri/nodif_brain_mask.nii.gz

$fs bedpostx_preproc.sh ${trdir}/${sub}_ses-post.long.${sub}/dmri &
$fs bedpostx_preproc.sh ${trdir}/${sub}_ses-pre.long.${sub}/dmri &

wait

for i in {0..$n_vols}
do
$fs bedpostx_single_slice.sh ${trdir}/${sub}_ses-post.long.${sub}/dmri $i --nf=2 --fudge=1 --bi=1000 --nj=1250 --se=25 --model=1 --cnonlinear &
$fs bedpostx_single_slice.sh ${trdir}/${sub}_ses-pre.long.${sub}/dmri $i --nf=2 --fudge=1 --bi=1000 --nj=1250 --se=25 --model=1 --cnonlinear &
done

wait

$fs bedpostx_postproc.sh ${trdir}/${sub}_ses-post.long.${sub}/dmri &
$fs bedpostx_postproc.sh ${trdir}/${sub}_ses-pre.long.${sub}/dmri &

wait

# Tractography
echo "BEGINNING TRACTOGRAPHY"

$fs trac-paths -c ${trdir}/${sub}/scripts/dmrirc.local -log ${trdir}/${sub}/trac-all.log -cmd ${trdir}/${sub}/scripts/trac-all.cmd

echo "DONE"
