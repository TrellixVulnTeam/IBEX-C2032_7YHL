#! /bin/bash
#SBATCH --job-name=Bed
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mail-user=yongkang.long@kaust.edu.sa
#SBATCH --mail-type=END
#SBATCH --output=LOG/log.%J
#SBATCH --error=LOG/err.%J
#SBATCH --time=4:00:00
#SBATCH --mem=100G
##SBATCH -a 0
##SBATCH --gres=gpu:1

polyAthreshold=-1
ENS="/home/longy/cnda/ensembl/Homo_sapiens.GRCh38.103.gtf.gz"
coverage="THLE2_Control.pAs.coverage.18.txt"
target="THLE2_Control.pAs.18.bed"
new="THLE2_Control.usage.18.txt"
#coverage="THLE2_Control.pAs.coverage.txt"
#target="thle2.bed"
#new="THLE2_Control.pAs.usage.txt"
mod1="../../Split_BL6/polyA_seq/modTHLE2_1.bed"
mod2="../../Split_BL6/polyA_seq/modTHLE2_2.bed"

perl generate_bed.pl $coverage $target
bedtools coverage -a $target -b $mod1 -S -sorted -counts > $target.021.counts
bedtools coverage -a $target -b $mod2 -S -sorted -counts > $target.022.counts
perl merge_rep.pl $target.021.counts $target.022.counts $target.info

perl calculate_usage.tianbin.pl $coverage $target.info $new  $ENS $polyAthreshold


rm $target $target.021.counts $target.022.counts $target.info $target.info.cutoff
