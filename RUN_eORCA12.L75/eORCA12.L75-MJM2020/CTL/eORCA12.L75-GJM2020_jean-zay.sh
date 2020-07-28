#!/bin/bash
#SBATCH --nodes=70
#SBATCH --ntasks=2080
#SBATCH --ntasks-per-node=40
#SBATCH --hint=nomultithread  
#SBATCH -J nemo_jean-zay
#SBATCH -e nemo_jean-zay.e%j
#SBATCH -o nemo_jean-zay.o%j
#SBATCH -A cli@cpu
#SBATCH --time=3:30:00
#SBATCH --exclusive

set -x
ulimit -s 
ulimit -s unlimited

CONFIG=eORCA12.L75
CASE=GJM2020

CONFCASE=${CONFIG}-${CASE}
CTL_DIR=$PDIR/RUN_${CONFIG}/${CONFCASE}/CTL
export  FORT_FMT_RECL=255

# Following numbers must be consistant with the header of this job
export NB_NPROC=2000   # number of cores used for NEMO
export NB_NPROC_IOS=80  # number of cores used for xios (number of xios_server.exe)
export NB_NCORE_DP=4   # activate depopulated core computation for XIOS. If not 0, RUN_DP is
                       # the number of cores used by XIOS on each exclusive node.
# Rebuild process 
export MERGE=0         # 1 = on the fly rebuild, 0 = dedicated job
export NB_NPROC_MER=30 # number of cores used for rebuild on the fly  (1/node is a good choice)
export NB_NNODE_MER=2  # number of nodes used for rebuild in dedicated job (MERGE=0). One instance of rebuild per node will be used.
export WALL_CLK_MER=3:00:00   # wall clock time for batch rebuild
export ACCOUNT=cli@cpu # account to be used

date
export I_MPI_ADJUST_ALLREDUCE=3

#
echo " Read corresponding include file on the HOMEWORK "
.  ${CTL_DIR}/includefile.sh

. $RUNTOOLS/lib/function_4_all.sh
. $RUNTOOLS/lib/function_4.sh
#  you can eventually include function redefinitions here (for testing purpose, for instance).
. $RUNTOOLS/lib/nemo4.sh
