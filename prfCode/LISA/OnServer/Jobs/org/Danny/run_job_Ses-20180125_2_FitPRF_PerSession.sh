#PBS -S /bin/bash
#PBS -N FitPRF_PerSession_20180125_15:28
#PBS -j oe
#PBS -lnodes=1:ppn=6:mem64gb
#PBS -lwalltime=72:00:00
#PBS -o $HOME/PRF/Logs/
#

echo "Job $PBS_JOBID started at `date`. Subject: danny, Session: 20180125, Slices: 15:28" | mail $USER -s "Job $PBS_JOBID"

mkdir $TMPDIR/PRF
cp -r $HOME/PRF/Data/us_reg/danny/ses-20180125* $TMPDIR/PRF
cp -r $HOME/PRF/Data/mask/danny/* $TMPDIR/PRF
cp -r $HOME/PRF/Code/* $TMPDIR/PRF
cd $TMPDIR/PRF

chmod +x $TMPDIR/PRF/BashScripts/pRF_run_CompiledMatlab_LISA.sh

$TMPDIR/PRF/BashScripts/pRF_run_CompiledMatlab_LISA.sh \
	pRF_FitModel_LISA danny 20180125 15:28 [5] \
	/home/pcklink/PRF/Logs/ \
	$TMPDIR/PRF/


echo "Job $PBS_JOBID ended at `date`. Subject: danny, Session: 20180125, Slices: 15:28" | mail $USER -s "Job $PBS_JOBID"

exit $?
