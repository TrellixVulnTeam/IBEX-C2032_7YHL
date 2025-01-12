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

:<<BL
sample="bl6_rep1"
ENS="/home/longy/cnda/ensembl/Mus_musculus.GRCm38.102.gtf.gz";
coverage="../../Split_BL6_PolyARead/usage_data/${sample}.pAs.coverage.txt"
#data="../../Split_BL6_PolyARead/usage_data/BL6_REP1.pAs.predict.aug8_SC_p5r10u0.05_4-0026.12.2.txt"
#testid='predict.aug8_SC_p5r10u0.05_4-0026.12.2'
#target="BL6.REP1.pAs.${testid}.bed"
#new="BL6_REP1.pAs.${testid}.usage.txt"
target="${sample}.pAs.bed"
new="${sample}.pAs.usage.txt"
mod1="modMSX_021.bed"
mod2="modMSX_022.bed"
BL
:<<BL
ENS="/home/longy/cnda/ensembl/Homo_sapiens.GRCh38.103.gtf.gz"
coverage="../../Split_BL6_PolyARead/usage_data/HepG2_Control.pAs.coverage.txt"
target="HepG2_Control.pAs.bed"
new="HepG2_Control.pAs.usage.txt"
#coverage="../../Split_BL6_PolyARead/usage_data/HepG2_Control.pAs.single_kermax6.HepG2_Control_aug8_SC_p1r5u0.05_4-0148.txt"
#testid='HepG2_Control.pAs.single_kermax6.HepG2_Control_aug8_SC_p1r5u0.05_4'
#target="HepG2_Control.${testid}.pAs.bed"
#new="HepG2_Control.pAs.${testid}.usage.txt"
mod1="modHepG2_3.bed"
mod2="modHepG2_4.bed"
BL
#:<<BL
ENS="/home/longy/cnda/ensembl/Homo_sapiens.GRCh38.103.gtf.gz"
coverage="../../Split_BL6_PolyARead/usage_data/K562_Chen.pAs.merge.coverage.txt"
#testid="oldmodel"
#target="K562_Chen.${testid}.pAs.bed"
#new="K562_Chen.pAs.${testid}.usage.txt"
target="K562_Chen.pAs.bed"
new="K562_Chen.pAs.usage.txt"
mod1="modK562_Chen.bed"
#mod1="modK562_Scramble_1.bed"
#mod2="modK562_Scramble_2.bed"
#BL

#:<<BL
bam="K562_Chen.3seq.bam"
uniqueBam="K562_Chen.3seq.uniqueMapped.bam"
uniqueBed="K562_Chen.3seq.uniqueMapped.bed"
samtools view -q 255 -f 2 -@ 16 $bam -b -o tem.bam 
echo "Fnished get unique mapped reads"
samtools sort tem.bam -@ 16 -o $uniqueBam
echo "Fnished sorting bam"
rm tem.bam
bedtools bamtobed -i $uniqueBam > $uniqueBed
echo "Finished transfer bam to bed"
perl change_postion.pl $uniqueBed $mod1
echo "Fnished change position"
#perl change_postion.pl HepG2_3.bed $mod1
#perl change_postion.pl HepG2_4.bed $mod2
#BL

perl generate_bed.pl $coverage $target
bedtools coverage -a $target -b $mod1 -S -sorted -counts > $target.021.counts
#bedtools coverage -a $target -b $mod2 -S -sorted -counts > $target.022.counts
perl merge_rep.pl $target.021.counts $target.021.counts $target.info

perl calculate_usage.tianbin.pl $coverage $target.info $target.info.cutoff $ENS

perl process_error_name.pl $ENS $target.info.cutoff  $new
rm $target $target.021.counts $target.022.counts $target.info $target.info.cutoff
