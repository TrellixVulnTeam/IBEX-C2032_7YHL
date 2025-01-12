#!/bin/bash
#SBATCH --job-name=mountainClimber
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mail-user=yongkang.long@kaust.edu.sa
#SBATCH --mail-type=END
#SBATCH --output=LOG/log.%J
#SBATCH --time=50:00:00
#SBATCH -a 0-19
#SBATCH --mem=140G
##SBATCH --gres=gpu:1
##SBATCH --dependency afterok:6686802_[1-100] 

#source activate ML

echo "This is job #${SLURM_ARRAY_JOB_ID}, task id ${SLURM_ARRAY_TASK_ID}"
chrs=("1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12" "13" "14" "15" "16" "17" "18"  "19" "X")  

chr=${chrs[$SLURM_ARRAY_TASK_ID]}

#samtools view -b BL6_REP1.bam $chr >BAM/chr$chr.bam

chr='3'
SAMPLE="BL6_TEST.chr$chr"
CHROM="BAM/chr$chr.chrom.size"
GTF="BAM/chr$chr.gtf"
FA="/home/longy/cnda/ensembl/chromsome/mm10.$chr.fa"
BAM="BAM/chr$chr.bam"

:<<BL
python ./src/get_junction_counts.py -i $BAM -s fr-unstrand -o ./junctions/$SAMPLE.bed

bedtools genomecov -trackline -bg -split -ibam $BAM -g $CHROM > ./bedgraph/$SAMPLE.bedgraph

python ./src/mountainClimberTU.py -b ./bedgraph/$SAMPLE.bedgraph -j ./junctions/$SAMPLE.bed -s 0 -g $CHROM  -o mountainClimberTU/${SAMPLE}_tu.bed
BL

python ./src/merge_tus3.py -i ./mountainClimberTU/${SAMPLE}_tu.bed --ss n -g $GTF  -o tus_merged/tus_merged

python ./src/mountainClimberCP.py -i ./bedgraph/$SAMPLE.bedgraph -g tus_merged/tus_merged.annot.chr${chr}_singleGenes.bed  -j ./junctions/$SAMPLE.bed -o mountainClimberCP/$SAMPLE.bed -x $FA

python ./src/mountainClimberRU.py -i mountainClimberCP/$SAMPLE.bed -o mountainClimberRU/$SAMPLE.bed
