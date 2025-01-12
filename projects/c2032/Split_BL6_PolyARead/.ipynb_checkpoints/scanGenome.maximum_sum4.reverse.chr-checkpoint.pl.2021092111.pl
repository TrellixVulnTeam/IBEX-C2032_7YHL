#!/usr/bin/perl -w
#
#
#Upate 2020/07/06
#Update 2021/04/15 Add peak

use POSIX;
my ($maxLength,$penality,$input) = @ARGV;

my $output = $input;
$output =~ s/predict/maxSum/;
$output .= ".right.$maxLength.$penality.txt";
open OUT,">$output";
print OUT "pas_id\tmaxPoint\tmaxPos\tstart\tend\n";


&maxSum($input);

sub maxSum{
	my ($file) = @_;
	open FILE,$file;
	my %predict;
	my %coor2pas;
	while(<FILE>){
		chomp;
		my ($pas_id,$prediction) = split;
		my ($chr,$coor,$srd) =  split /\:/,$pas_id;
		$predict{$coor} = $prediction;
		$coor2pas{$coor} = $pas_id;
	}

	my $sum = 0;
	my $maxPoint = 0;
	$predict{-1} = 1;
	$coor2pas{-1} = "chr";
	my @coor = sort{$b<=>$a} keys %predict;
	my $start = $coor[0];
	my $end = $coor[0];
	my $maxPos = $coor[0];
	my $peak = $coor[0];
	my $peak_score = 0;
	foreach my $coor (@coor){
		my $prediction = $predict{$coor};
		if($coor-$end<-1){
			if($sum >0 && $maxPoint > $maxLength){
				my $pas_id = $coor2pas{$maxPos};
				print OUT "$pas_id\t$maxPoint\t$maxPos\t$start\t$end\t$peak\n";
			}
			$start = $coor;
			$sum = 0;
			$maxPoint = 0;
			$peak_score = 0;
			$end = $coor;
		}
		#####Sigmoid
		elsif($prediction <= 0.5){
			$sum -= $penality;
		#####Tanh
		#elsif($prediction <= 0){
		#	$sum -= $penality;
			#$sum += $prediction;
			if($sum <= 0){
				if($maxPoint > $maxLength){
					my $pas_id = $coor2pas{$maxPos};
					print OUT "$pas_id\t$maxPoint\t$maxPos\t$start\t$end\t$peak\n";
				}
				$start = $coor;
				$sum = 0;
				$maxPoint = 0;
				$peak_score = 0;
			}
			$end = $coor;
		}
		else{
			$sum += $prediction;
			if($peak_score < $prediction){
				$peak_score = $prediction;
				$peak = $coor;
			}
			if($maxPoint < $sum){
				$maxPoint = $sum;
				$maxPos = $coor;
			}
			if($sum < 1){
				$start = $coor;
				$maxPoint = $sum;
				$maxPos = $coor
			}
			$end = $coor;
		}
	}
}
