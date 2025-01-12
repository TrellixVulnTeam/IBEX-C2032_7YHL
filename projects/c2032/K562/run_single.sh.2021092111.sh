#!/bin/bash
#SBATCH --job-name=train
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mail-user=yongkang.long@kaust.edu.sa
#SBATCH --mail-type=END
#SBATCH --output=LOG/log.%J
#SBATCH --time=3:00:00
#SBATCH --mem=50G
#SBATCH --gres=gpu:1
##SBATCH -a 0-39
##SBATCH --dependency afterok:6686802_[1-100] 

#########TRAIN
######Yongkang Long Update at Jan 05, 2021. 
######Tommorrow. I have to write function of data augmentation. Augmentation every epoch

echo "This is job #${SLURM_ARRAY_JOB_ID}, task id ${SLURM_ARRAY_TASK_ID}"

##########################################################################
#########PARAMETER CHANGED
prob=0.00306 ##### 8: 0.00752  16:0.01459 0:000442
sample="K562_ZRANB2"
Shift=8
augmentation="aug$Shift" ####augmentation= [AUG NOAUG]
#augmentation="aug" ####augmentation= [AUG NOAUG]
polyASeqRCThreshold=10
RNASeqRCThoreshold=30
combination='SC' ####combination = [SCP SC SP CP S C P]
round=5
bestEpoch=0319
epochs=500
learning_rate=2e-4 #####small learning rate for fine tuning
maxPoint=9
task="evaluation"   ##task = [preparation training evaluation statistics]
roundName="${augmentation}_${combination}_p${polyASeqRCThreshold}r${RNASeqRCThoreshold}_${round}"
trainid="hg38.pAs.single_kermax6"
#########PARAMETER CHANGED
###########################################################################


###########################################################################
###########IMPORTANT FILE PATH
dir="../Split_BL6/${sample}_data/Blocks"
PAS="../Split_BL6_PolyARead/usage_data/${sample}.pAs.usage.txt"
DB="../Split_BL6_PolyARead/usage_data/${sample}.pAs.coverage.txt"
info="../Split_BL6/${sample}_data/Blocks/info.txt"
polyAfile="../Split_BL6_PolyARead/BAM/BL6_REP1.PolyACount.txt"

number=$round
((number-=1))
oldroundName=${roundName:0:-1}$number
oldmodel="Model/${trainid}.${oldroundName}-${bestEpoch}.ckpt"

Testid="${trainid}.${roundName}-${bestEpoch}"
model="Model/${Testid}.ckpt"
###########IMPORTANT FILE PATH
###########################################################################


#cd /home/longy/project/Split_BL6/
#python split_chr.py
#####Prepare data
if [ "$task" == "preparation" ]; then
	echo "starting task $task"
	####Extract PolyA 
	#perl extract.polyA.reads.pl BAM/BL6_REP1.sortedByName.bam BAM/BL6_REP1.0.8.bed PE
	sbatch --job-name='Prepare' --array=0-133 --time=1:00:00 --export=dir=$dir,PAS=$PAS,round=$roundName,task='pre',augmentation=$augmentation,prob=$prob,polyASeqRCThreshold=$polyASeqRCThreshold,RNASeqRCThoreshold=$RNASeqRCThoreshold,Shift=$Shift run_array_blocks.sh


elif [ "$task" == "get" ]; then
	echo "starting task $task"
	####Extract PolyA 
	#perl extract.polyA.reads.pl BAM/BL6_REP1.sortedByName.bam BAM/BL6_REP1.0.8.bed PE
	sbatch --job-name='get' --array=0-133 --export=dir=$dir,Testid=$Testid,maxPoint=$maxPoint,task='get' run_array_blocks.sh

elif [ "$task" == "training" ]; then
	echo "starting task $task"
	#python3 prep_data.py --root_dir data --round $roundName  --out bl6.pAst.text.npz
	echo $oldmodel
	python3 train.py --root_dir data --block_dir $dir --round $roundName  --trainid $trainid.$roundName --model $oldmodel --polyAfile $polyAfile  --combination $combination --learning_rate $learning_rate --epochs $epochs


elif [ "$task" == "evaluation" ]; then
	###Num of Train: 144, Num of valid 36, Num of test: 21
	echo "starting task $task"
	#sbatch --job-name='Eva_train' --array=0-111   --export=dir=$dir,PAS=$PAS,DB=$DB,info=$info,Testid=$Testid,model=$model,round=$roundName,combination=$combination,polyAfile=$polyAfile,polyASeqRCThreshold=$polyASeqRCThreshold,RNASeqRCThoreshold=$RNASeqRCThoreshold,Shift=$Shift,maxPoint=$maxPoint,setName='train',task='eva' run_array_blocks.sh
	#sbatch --job-name='Eva_valid' --array=0-27 --export=dir=$dir,PAS=$PAS,DB=$DB,info=$info,Testid=$Testid,model=$model,round=$roundName,combination=$combination,polyAfile=$polyAfile,polyASeqRCThreshold=$polyASeqRCThreshold,RNASeqRCThoreshold=$RNASeqRCThoreshold,Shift=$Shift,maxPoint=$maxPoint,setName='valid',task='eva' run_array_blocks.sh
	sbatch --job-name='Eva_test' --array=0-1 --export=dir=$dir,PAS=$PAS,DB=$DB,info=$info,Testid=$Testid,model=$model,round=$roundName,combination=$combination,polyAfile=$polyAfile,polyASeqRCThreshold=$polyASeqRCThreshold,RNASeqRCThoreshold=$RNASeqRCThoreshold,Shift=$Shift,maxPoint=$maxPoint,setName='test',task='eva'  run_array_blocks.sh


elif [ "$task" == "statistics" ]; then
	echo "starting task $task"
	python merge_postpropose.py --root_dir=$dir --round=$roundName --trainid=$Testid --sets='train' --maxPoint $maxPoint
	python merge_postpropose.py --root_dir=$dir --round=$roundName --trainid=$Testid --sets='valid' --maxPoint $maxPoint
    #python merge_postpropose.py --root_dir=$dir --round=$roundName --trainid=$Testid --sets='test'

else
	echo "Invalid task parameter"
	echo "task = [preparation training evaluation statistics]"
fi
