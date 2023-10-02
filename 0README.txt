GIT Command cheat-sheet:

feigl@askja T91_askja]$ cd /home/batzli/bin_htcondor/
[feigl@askja bin_htcondor]$ git status
On branch master
Your branch is ahead of 'origin/master' by 2 commits.
  (use "git push" to publish your local commits)

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   pair2e.sh
        modified:   run_pair_DAG_gmtsarv60.sh
        modified:   run_pair_gmtsarv60.sh

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        p2p_processingKF.csh

no changes added to commit (use "git add" and/or "git commit -a")



# 2021/03/17 to 18

# Marathon debugging with Sam

# here is a successful example
#ls /s12/batzli/old_runs/In20201023_20201114.works/intf
ls -l /s12/batzli/old_runs/In20201023_20201114.works/raw
head /s12/batzli/old_runs/In20201023_20201114.works/run.sh

# start here
cd /s12/feigl
source /home/batzli/setup.sh

# we should need only one file:
cp /s12/feigl/SANEM/TSX/T91_askja/PAIRSmake.txt .

# clean start
rm -rf RAW T91 dem In* *.sub config.tsx.txt

# do it
run_pair_DAG_gmtsarv60.sh PAIRSmake.txt  

# logging success:
mkdir -p SANEM/TSX/T91_askja
cp -rp  In* RAW *.sub dem PAIRSmake SANEM/TSX/T91_askja
cp -rp  PAIRSmake* SANEM/TSX/T91_askja
