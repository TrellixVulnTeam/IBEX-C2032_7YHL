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


ENS="/home/longy/cnda/ensembl/Homo_sapiens.GRCh38.101.gtf.gz";

data="../usage_data/hg38.pAs.readCount.Overlap.txt"
#data="../../Split_BL6_PolyARead/usage_data/HUM_Brain.pAs.coverage.txt"
target="hg38.pAs.tianbin.Overlap"

#perl merge_rep.pl /home/longy/workspace/apa_predict/pas_dataset/GSM747473_human_maqc-brain1.sites.clustered.hg19.bed /home/longy/workspace/apa_predict/pas_dataset/GSM747474_human_maqc-brain2.sites.clustered.hg19.bed  $target.info


perl calculate_usage.tianbin.pl $data /home/longy/workspace/apa_predict/pas_dataset/human.pAs.brain.hg38.union.bed $target.info.cutoff $ENS

new="hg38.pAs.tianbin.Overlap.usage.txt"
#perl overlap.pl
#perl process_error_name.pl $ENS $target.info.cutoff $new
