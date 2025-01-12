#!/bin/bash
#SBATCH --job-name=train
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mail-user=yongkang.long@kaust.edu.sa
#SBATCH --mail-type=END
#SBATCH --output=LOG/log.%J
#SBATCH --time=4:00:00
#SBATCH --mem=100G
#SBATCH --gres=gpu:1
#SBATCH --dependency afterok:15061029_[0-191] 
##SBATCH -a 0-39

#########TRAIN
######Yongkang Long Update at Jan 05, 2021. 
######Tommorrow. I have to write function of data augmentation. Augmentation every epoch
#""""Check bl6 gene number""""
echo "This is job #${SLURM_ARRAY_JOB_ID}, task id ${SLURM_ARRAY_TASK_ID}"

##########################################################################
#########PARAMETER CHANGED
prob=1 ##### K562 0.00922
Shift=8
augmentation="aug$Shift" ####augmentation= [AUG NOAUG]
combination='SC' ####combination = [SCP SC SP CP S C P]
epochs=500
maxPoint=12
penality=1
######Modified distance<38 PAS usage jiaquan
######Check gene RPS8 chr1:44778703 44778755
spe='K562'
bestEpoch=0328
round=2
learning_rate=1e-3 #####small learning rate for fine tuning
task='statistics'   ##task = [preparation training evaluation statistics]
if [ "$spe" == "HepG2" ]; then
	ENS='/home/longy/cnda/ensembl/Homo_sapiens.GRCh38.102.gtf.gz'
	sample="HepG2_Control"
	block_num=255   #Control 255 ETF1 272
	polyASeqRCThreshold=1
	RNASeqRCThreshold=5
	usageThreshold=0.05
	trainid="${sample}.pAs"
	#trainid="HepG2_Control.pAs.single_kermax6"
	#roundName="Hepg2_Control_${augmentation}_${combination}_p${polyASeqRCThreshold}r${RNASeqRCThreshold}u${usageThreshold}_${round}"


elif [ "$spe" == "K562" ]; then
	ENS='/home/longy/cnda/ensembl/Homo_sapiens.GRCh38.102.gtf.gz'
	sample="K562_Long"
	block_num=119
	polyASeqRCThreshold=3
	RNASeqRCThreshold=9
	usageThreshold=0.05
	maxPoint=12
	penality=1
	trainid="${sample}.pAs.single_kermax6"

elif [ "$spe" == "pc" ]; then
	ENS='/home/longy/cnda/ensembl/Mus_musculus.GRCm38.102.gtf.gz'
	sample="BL6_ProteinCoding"
	block_num=247
	polyASeqRCThreshold=5
	RNASeqRCThreshold=10
	usageThreshold=0.05

elif [ "$spe" == "BL6" ]; then
	ENS='/home/longy/cnda/ensembl/Mus_musculus.GRCm38.102.gtf.gz'
	sample="BL6_REP1"
	block_num=247
	polyASeqRCThreshold=5
	RNASeqRCThreshold=10
	usageThreshold=0.05
	maxPoint=12
	penality=2
	trainid="${sample}.pAs.single_kermax6"

elif [ "$spe" == "regression" ]; then
	file_path="usage_data/BL6_REP1.pAs.predict.coverage.txt"
	trainid="BL6_REP1_log_mse"
fi
roundName="${sample}_${augmentation}_${combination}_p${polyASeqRCThreshold}r${RNASeqRCThreshold}u${usageThreshold}_${round}"
#if [ "$combination" == "SC" ]; then
#	trainid="${sample}.pAs.single_kermax6"
#else
#	trainid="${sample}.pAs.${combination}_kermax6"
#fi
block_idx=$(($block_num-1))
valid_idx=$(($block_num/5-1))
train_idx=$(($block_num/5*4-1))
test_idx=$(($block_num%5-1))
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
	sbatch --job-name='Prepare' --array=0-$block_idx --export=dir=$dir,ENS=$ENS,PAS=$PAS,round=$roundName,task='pre',augmentation=$augmentation,prob=$prob,polyASeqRCThreshold=$polyASeqRCThreshold,RNASeqRCThreshold=$RNASeqRCThreshold,usageThreshold=$usageThreshold,Shift=$Shift run_array_blocks.sh


elif [ "$task" == "get" ]; then
	echo "starting task $task"
	####Extract PolyA 
	#perl extract.polyA.reads.pl BAM/BL6_REP1.sortedByName.bam BAM/BL6_REP1.0.8.bed PE
	sbatch --job-name='get' --array=0-$block_idx --export=dir=$dir,ENS=$ENS,PAS=$PAS,Testid=$Testid,maxPoint=$maxPoint,penality=$penality,task='get' run_array_blocks.sh

elif [ "$task" == "training" ]; then
	echo "starting task $task"
	#python3 prep_data.py --root_dir data --round $roundName  --out bl6.pAst.text.npz
	echo $oldmodel
	python3 train.py --root_dir data --block_dir $dir --round $roundName  --trainid $trainid.$roundName --model $oldmodel --polyAfile $polyAfile  --combination $combination --learning_rate $learning_rate --epochs $epochs

elif [ "$task" == "regression" ]; then
	echo "starting task $task"
	python3 train.regression.py --file_path $file_path --trainid $trainid --learning_rate $learning_rate --epochs $epochs --shift $Shift


elif [ "$task" == "evaluation" ]; then
	###Num of Train: 144, Num of valid 36, Num of test: 21
	echo "starting task $task"
	sbatch --job-name='Eva_train' --array=0-$train_idx --export=dir=$dir,ENS=$ENS,PAS=$PAS,DB=$DB,info=$info,Testid=$Testid,model=$model,round=$roundName,combination=$combination,polyAfile=$polyAfile,polyASeqRCThreshold=$polyASeqRCThreshold,RNASeqRCThreshold=$RNASeqRCThreshold,usageThreshold=$usageThreshold,Shift=$Shift,maxPoint=$maxPoint,penality=$penality,setName='train',task='eva' run_array_blocks.sh
	sbatch --job-name='Eva_valid' --array=0-$valid_idx --export=dir=$dir,ENS=$ENS,PAS=$PAS,DB=$DB,info=$info,Testid=$Testid,model=$model,round=$roundName,combination=$combination,polyAfile=$polyAfile,polyASeqRCThreshold=$polyASeqRCThreshold,RNASeqRCThreshold=$RNASeqRCThreshold,usageThreshold=$usageThreshold,Shift=$Shift,maxPoint=$maxPoint,penality=$penality,setName='valid',task='eva' run_array_blocks.sh
	sbatch --job-name='Eva_test' --array=0-$test_idx --export=dir=$dir,ENS=$ENS,PAS=$PAS,DB=$DB,info=$info,Testid=$Testid,model=$model,round=$roundName,combination=$combination,polyAfile=$polyAfile,polyASeqRCThreshold=$polyASeqRCThreshold,RNASeqRCThreshold=$RNASeqRCThreshold,usageThreshold=$usageThreshold,Shift=$Shift,maxPoint=$maxPoint,penality=$penality,setName='test',task='eva' run_array_blocks.sh


elif [ "$task" == "statistics" ]; then
	echo "starting task $task"
	python merge_postpropose.py --root_dir=$dir --round=$roundName --trainid=$Testid --sets='train' --maxPoint $maxPoint --penality $penality
	python merge_postpropose.py --root_dir=$dir --round=$roundName --trainid=$Testid --sets='valid' --maxPoint $maxPoint --penality $penality
    python merge_postpropose.py --root_dir=$dir --round=$roundName --trainid=$Testid --sets='test' --maxPoint $maxPoint --penality $penality

else
	echo "Invalid task parameter"
	echo "task = [preparation training evaluation statistics]"
fi
