#!/bin/bash
#
# This bash-script submits all jobs to the server, instead of running them locally.
# If you want to submit only some jobs to the server,simply add a "#" in front of 
#the ones you like to ommit and execute the script then.
#

mkdir -p $HOME/PRF/Logs/slurm
cd $HOME/PRF/Logs/slurm
chmod +x $HOME/PRF/Code/Jobs/*

sbatch  $HOME/PRF/Code/Jobs/run_job_Ses-AllSessions-avg-cv_1_FitPRF_linhrf_cv1_dhrf_neggain_danny.sh
sbatch  $HOME/PRF/Code/Jobs/run_job_Ses-AllSessions-avg-cv_2_FitPRF_linhrf_cv1_dhrf_neggain_danny.sh
sbatch  $HOME/PRF/Code/Jobs/run_job_Ses-AllSessions-avg-cv_3_FitPRF_linhrf_cv1_dhrf_neggain_danny.sh
sbatch  $HOME/PRF/Code/Jobs/run_job_Ses-AllSessions-avg-cv_4_FitPRF_linhrf_cv1_dhrf_neggain_danny.sh

sbatch  $HOME/PRF/Code/Jobs/run_job_Ses-AllSessions-avg-cv_1_FitPRF_linhrf_cv1_dhrf_neggain_eddy.sh
sbatch  $HOME/PRF/Code/Jobs/run_job_Ses-AllSessions-avg-cv_2_FitPRF_linhrf_cv1_dhrf_neggain_eddy.sh
sbatch  $HOME/PRF/Code/Jobs/run_job_Ses-AllSessions-avg-cv_3_FitPRF_linhrf_cv1_dhrf_neggain_eddy.sh
sbatch  $HOME/PRF/Code/Jobs/run_job_Ses-AllSessions-avg-cv_4_FitPRF_linhrf_cv1_dhrf_neggain_eddy.sh

sbatch  $HOME/PRF/Code/Jobs/run_job_Ses-AllSessions-avg-cv_1_FitPRF_linhrf_cv1_mhrf_neggain_danny.sh
sbatch  $HOME/PRF/Code/Jobs/run_job_Ses-AllSessions-avg-cv_2_FitPRF_linhrf_cv1_mhrf_neggain_danny.sh
sbatch  $HOME/PRF/Code/Jobs/run_job_Ses-AllSessions-avg-cv_3_FitPRF_linhrf_cv1_mhrf_neggain_danny.sh
sbatch  $HOME/PRF/Code/Jobs/run_job_Ses-AllSessions-avg-cv_4_FitPRF_linhrf_cv1_mhrf_neggain_danny.sh

sbatch  $HOME/PRF/Code/Jobs/run_job_Ses-AllSessions-avg-cv_1_FitPRF_linhrf_cv1_mhrf_neggain_eddy.sh
sbatch  $HOME/PRF/Code/Jobs/run_job_Ses-AllSessions-avg-cv_2_FitPRF_linhrf_cv1_mhrf_neggain_eddy.sh
sbatch  $HOME/PRF/Code/Jobs/run_job_Ses-AllSessions-avg-cv_3_FitPRF_linhrf_cv1_mhrf_neggain_eddy.sh
sbatch  $HOME/PRF/Code/Jobs/run_job_Ses-AllSessions-avg-cv_4_FitPRF_linhrf_cv1_mhrf_neggain_eddy.sh