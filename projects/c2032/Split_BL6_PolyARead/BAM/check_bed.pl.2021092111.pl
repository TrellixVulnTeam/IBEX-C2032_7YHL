#!/usr/bin/perl -w

open FILE,"BL6_REP1.skip.bed";
my %hash;
while(<FILE>){
	chomp;
	my ($chr,$start,$end,$read_name,$AS,$strand) = split /\t/;
	next if $chr eq "Y" || $chr eq "MT";
	$chr = "chr$chr";
	if($strand eq "+"){
		if(exists $hash{"$chr:$end:$strand"}){
			$hash{"$chr:$end:$strand"} += 1;
		}
		else{
			$hash{"$chr:$end:$strand"} = 1;
		}
	}
	else{
		if(exists $hash{"$chr:$start:$strand"}){
			$hash{"$chr:$start:$strand"} += 1;
		}
		else{
			$hash{"$chr:$start:$strand"} = 1;
		}
	}
}

open OUT,">BL6_REP1.PolyACount.txt";
#while(my ($key,$val) = each %hash){
foreach my $key (sort keys %hash){
	$val = $hash{$key};
	print OUT "$key\t$val\n";
}

