#!/usr/bin/perl -w

my ($inp,$out) = @ARGV;
#open FILE,"scanGenome_data/bl6.pAs.scanGenome.step1.str1.REP1.chr1.Trimmed10.txt";
#open FILE,"data/bl6.pAs.positive.REP1.newround0.txt";
open FILE,"$inp";
my $header = <FILE>;
open OUT,">$out";
print OUT "$header";
while(<FILE>){
	chomp;
	my @data = split;
	my $sum = 0;
	my $count = 0;
	for(my $i=8;$i<108;$i++){
		if($data[$i]>0){
			$sum += $data[$i];
			$count ++;
		}
	}
	next if $count ==0;
	my $trimMean = $sum/$count;
	if ($trimMean < 10){
		#print "$_\n";
	}
	else{
		print OUT "$_\n";
	}
}


