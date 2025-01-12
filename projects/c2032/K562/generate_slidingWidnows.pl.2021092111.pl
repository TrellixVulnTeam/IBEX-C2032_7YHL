#!/usr/bin/perl -w
###Modified Sep/22/2020

my ($WIG,$ScanGeomome,$window,$step,$srd,$chr,$spe) = @ARGV;

my %chr;
$chr = substr($chr,3);
open REF,"/ibex/scratch/longy/cnda/ensembl/oneLine/$spe.$chr.fa";
print "/ibex/scratch/longy/cnda/ensembl/oneLine/$spe.$chr.fa\n";
$chr{$chr} = <REF>;
my @motif;
if($spe eq "mm10"){
	@motif = qw/AAGAAA AATAAA AATACA AATAGA AATATA AATGAA ACTAAA AGTAAA ATTAAA CATAAA GATAAA TATAAA AAAAAG/;
}
elsif($spe eq "hg38"){
	@motif = qw/AAGAAA AATAAA AATACA AATAGA AATATA ACTAAA AGTAAA ATTAAA CATAAA  GATAAA TATAAA AAAAAG/;
}


open FILE,$WIG;
open OUT,">$ScanGeomome";
print OUT "pas_id\tpas_type\tchr\tpos\tstrand\tsymbol\tusage\tsequence\n";
my %cov;
<FILE>;
my $line = <FILE>;
chomp $line;
my ($pos,$read) = split /\t/,$line;
$cov{$pos} = $read;
my $old_pos = $pos;
while(<FILE>){
	chomp;
	my ($pos,$read) = split;
	$cov{$pos} = $read;
	my $diff = $pos-$old_pos;
	if($diff>$window){
		$diff = $window;
	}
	my @array = (0)x($window);
	my $sum=0;
	my $count=0;
	for(my$i=0;$i<$window/$step;$i++){
		my $pre_pos = $old_pos-$window+$i+1;
		if(exists $cov{$pre_pos}){
			$array[$i] = $cov{$pre_pos};
			$sum += $array[$i];
			$count++;
		}
	}
	#my $trimMean = $sum/$count;
	#for(my$j=0;$j<$diff && $trimMean>10;$j++){
	#Don't get the threshod now;
	for(my$j=0;$j<$diff;$j++){
		my $pasBeg = $old_pos-$window+1+$j;
		my $pasEnd = $old_pos+$j;
		my $pas_pos = $pasBeg+100;
		my $sequence = substr($chr{$chr},$pasBeg-1,$window);
		my @coverage = (0)x($window);
		@coverage[0..$window-$j-1] = @array[$j..$window-1];
		if($srd eq "-"){
			$sequence =~ tr/ATCG/TAGC/;
			$sequence = reverse $sequence;
			@coverage = reverse @coverage;
			$pas_pos = $pasBeg+75;
		}
		my $motifNum = 0;
		my $subseq = substr($sequence,63,32);
		foreach my $motif(@motif){
			$motifNum += ($subseq =~ s/$motif/$motif/g);
		}
		$pas_type = "motif=$motifNum";
		my $sum = 0;
		my $count = 0;
		my $max = 0;
		for(my $i=8;$i<108;$i++){
			if($coverage[$i]>0){
				$sum += $coverage[$i];
				$count++;
			}
			if($max < $coverage[$i]){
				$max = $coverage[$i];
			}
		}
		next if $count ==0;
		my $trimMean = $sum/$count;
		next if $trimMean < 10;
		print OUT "chr$chr:$pas_pos:$srd\t$pas_type\tchr$chr\t$pas_pos\t$srd\tNone\t1\t$sequence\t",join("\t",@coverage),"\n";
	}
	$old_pos = $pos;
}
