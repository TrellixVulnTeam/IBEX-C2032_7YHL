#! /bin/bash
#SBATCH --job-name=Bed
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --mail-user=yongkang.long@kaust.edu.sa
#SBATCH --mail-type=END
#SBATCH --output=log.%J
#SBATCH --time=1:00:00
#SBATCH --mem=24G
#SBATCH -a 0
#SBATCH --gres=gpu:1

cd /home/longy/project/K562/polyA_seq/

ENS="/home/longy/cnda/ensembl/Homo_sapiens.GRCh38.101.gtf.gz";

#data="../data/bl6.pAs.Predict.REP1.zbround6.txt"
#target="bl6.pAs.predict.zbround6.txt"

#data="../../DeeReCT-PolyARC_zhangnbinallprecision/zhangbin_data/bl6.pAs.raw.zhangbin.txt"
#target="bl6.pAs.zhangbin.bed"

data="../usage_data/hg38.pAs.readCount.Control_Overlap.txt"
target="hg38.pAs.tianbin.Control_Overlap"

perl generate_bed.pl $data $target.bed
bedtools coverage -a $target.bed -b modK562_Scramble_1.bed -S -sorted -counts > $target.Scramble1.counts
bedtools coverage -a $target.bed -b modK562_Scramble_2.bed -S -sorted -counts > $target.Scramble2.counts
perl merge_rep.pl $target.Scramble1.counts $target.Scramble2.counts $target.info



perl calculate_usage.tianbin.pl $data $target.info $target.info.cutoff $ENS

new="hg38.pAs.tianbin.Control_Overlap.usage.txt"
#perl overlap.pl
perl process_error_name.pl $ENS $target.info.cutoff $new.txt
