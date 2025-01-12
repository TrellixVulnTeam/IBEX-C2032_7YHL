#!/usr/bin/perl -w

use Statistics::Descriptive;

####Fix left<right pos2<pos2, should be at least 50% overlap Do not fixed Now
#### plus strand +0.5, minus strand -0.5
my ($maxLength,$penality,$PAS,$DB,$input,$INFO,$polyASeqRCThreshold,$RNASeqRCThreshold,$usageThreshold) = @ARGV;
my ($baseName) = (split /\/|\./,$input)[-2];
my ($CHR,$SRD) = split /\_/,$baseName;
print "Merge two direction prediction for $input\n";


open INFO,$INFO;
#<INFO>; ###Now no Header;
my %info;
while(<INFO>){
	chomp;
	my ($baseName,$start,$end) = split /\t/;
	$info{$baseName} = [$start,$end];
}


my $LEFT = $input;
$LEFT =~ s/predict/maxSum/;
#$LEFT .= ".left.$maxLength.$penality.txt";
$LEFT .= ".forward.0.$penality.txt";

my $RIGHT = $input;
$RIGHT =~ s/predict/maxSum/;
#$RIGHT .= ".right.$maxLength.$penality.txt";
$RIGHT .= ".reverse.0.$penality.txt";
my $OUT = $input;
$OUT =~ s/predict/maxSum/;
$OUT .= ".bidirection.$maxLength.$penality.txt";

my $STAT = $input;
$STAT =~ s/predict/Stat/;
$STAT .= ".bidirection.$maxLength.$penality.txt";


open STAT,">$STAT";

my @pas_left;
my %left_point;
my %pas_left;
my %peak_left;
open FILE,"$LEFT";
<FILE>;
while(<FILE>){
	chomp;
	my ($pas_id,$maxPoint,$maxPos,$start,$end,$peak) = split;
	next if $maxPoint < $maxLength;
	push @pas_left,$maxPos;
	$left_point{$maxPos} = $maxPoint;
	$pas_left{$maxPos} = $start;
	$peak_left{$maxPos} = $peak;
}


my @pas_right;
my %right_point;
my %pas_right;
my %peak_right;
open FILE,"$RIGHT";
<FILE>;
while(<FILE>){
	chomp;
	my ($pas_id,$maxPoint,$maxPos,$start,$end,$peak) = split;
	next if $maxPoint < $maxLength;
	push @pas_right,$maxPos;
	$right_point{$maxPos} = $maxPoint;
	$pas_right{$maxPos} = $start;
	$peak_right{$maxPos} = $peak;
}

@pas_right = reverse @pas_right;


my %pas_pos;
for (my$i=0,$j=0;$i<@pas_left && $j<@pas_right;){
	my $pos1 = $pas_left[$i];
	my $pos2 = $pas_right[$j];
	my $maxPoint1 = $left_point{$pos1};
	my $maxPoint2 = $right_point{$pos2};
	if($pos2>=$pos1){
		$i++;
	}
	elsif($pas_left{$pos1}>$pas_right{$pos2}){
		$j++;
	}
	else{
		my $pos = ($pos1+$pos2)/2;
		#my $pos = ($peak_left{$pos1}+$peak_right{$pos2})/2;
		if($SRD eq "+"){
			$pos += 0.5;
		}
		elsif($SRD eq "-"){
			$pos -= 0.5;
		}
		$pas_pos{$pos} = ($maxPoint2+$maxPoint1)/2;
		$i++;
		$j++;
	}
}



my %nearest;
my %nearReal;
my %usage;
my %usage2;
my $ground_truth = 0 ;
open FILE,"$PAS";
<FILE>;
my $previous = 0;
while(<FILE>){
	chomp;
	my ($pas_id,$pas_type,$chr,$end,$srd,$symbol,$usage,$polyASeqRC,undef,undef,$RNASeqRC) = split;
	next if $polyASeqRC < $polyASeqRCThreshold;
	next if $RNASeqRC   < $RNASeqRCThreshold;
	next if $usage < $usageThreshold;
	if ($srd eq $SRD && $chr eq $CHR && $end>=$info{$baseName}->[0] && $end<=$info{$baseName}->[1]){
		$ground_truth++;
		$previous = $end;
		while(my($pos,$val) = each %pas_pos){
			if(!exists $nearest{$pos} || abs($pos-$end)<abs($nearest{$pos})){
				$nearest{$pos} = $pos-$end;
				$nearReal{$pos} = "GT.$chr:$end:$srd";
				$usage{$pos} = "$chr:$end:$srd";
				$usage2{$pos} = $pos-$end;
			}
		}
	}
}

my $near_num = keys %nearest;
my $pas_num = keys %pas_pos;
print "$near_num\t$pas_num\n";


my $RealNum25 = 0;
my $RealNum50 = 0;
my $RealNum100 = 0;
while(my($pas_id,$diff) = each %nearest){
	if(abs($diff)<100){
		$RealNum100++;
		if(abs($diff)<50){
			$RealNum50++;
			if(abs($diff)<25){
				$RealNum25++;
			}
		}
	}
}
$recall25 = $RealNum25/$ground_truth;
$recall50 = $RealNum50/$ground_truth;
$recall100 = $RealNum100/$ground_truth;
print STAT "ground truth in $CHR\t$RealNum25\t$RealNum50\t$RealNum100\t$ground_truth\n";
print STAT "recall\t$recall25\t$recall50\t$recall100\n";


my %db;
my %db2;
open FILE,"$DB";
while(<FILE>){
	chomp;
	my ($pas_id,$pas_type,$chr,$end,$srd) = split;
	if ($srd eq $SRD && $chr eq $CHR && $end>=$info{$baseName}->[0] && $end<=$info{$baseName}->[1]){
		while(my($pos,$val) = each %pas_pos){
			if( abs($pos-$end)<abs($nearest{$pos})){
				$nearest{$pos} = $pos-$end;
				$nearReal{$pos} = "DB.$chr:$end:$srd";
			}
			if(!exists $db2{$pos} ||  abs($pos-$end)<abs($db2{$pos})){
				$db{$pos} = "$chr:$end:$srd";
				$db2{$pos} = $pos-$end;
			}
		}
	}
}


my $precis25 = 0;
my $precis50 = 0;
my $precis100 = 0;

open OUT,">$OUT";
print OUT "predict_pos\tnearestPasID\tdiff\tchr\tstrand\tgt_pasid\tgt_diff\tdb_pasid\tdb_diff\tmaxPoint\n";
my @stat;
foreach my $key (sort{$a<=>$b} keys %nearReal){
	my $val = $nearReal{$key};
	my $diff = $nearest{$key};
	my $usage = exists $usage{$key} ? $usage{$key} : "None";
	my $usage2 = exists $usage2{$key} ? $usage2{$key} : "NaN";
	my $db = exists $db{$key} ? $db{$key} : "None";
	my $db2 = exists $db2{$key} ? $db2{$key} : "NaN";
	print OUT "$key\t$val\t$diff\t$CHR\t$SRD\t$usage\t$usage2\t$db\t$db2\t$pas_pos{$key}\n";
	if(abs($diff)<100){
		$precis100++;
		if(abs($diff)<50){
			$precis50++;
			if(abs($diff)<25){
				push @stat,$diff;
				$precis25++;
			}
		}
	}
}

my $total = keys %pas_pos;
my $percent25 = $precis25/$total;
my $percent50 = $precis50/$total;
my $percent100 = $precis100/$total;
print STAT "precise\t$precis25\t$precis50\t$precis100\t$total\n";
print STAT "precision\t$percent25\t$percent50\t$percent100\n";

my $stat = Statistics::Descriptive::Full->new();
$stat->add_data(@stat);
my $mean = $stat->mean();#平均值
my $variance = $stat->variance();#方差
my $num = $stat->count();#data的数目
my $standard_deviation=$stat->standard_deviation();#标准差
my $sum=$stat->sum();#求和
my $min=$stat->min();#最小值
my $mindex=$stat->mindex();#最小值的index
my $max=$stat->max();#最大值
my $maxdex=$stat->maxdex();#最大值的index
my $range=$stat->sample_range();#最小值到最大值
my $median=$stat->median();

print STAT "Header\tRecall\tFPR\tMean\tMedian\tSTD\tRange\n";
print STAT "$penality,$maxLength\t$recall25\t$percent25\t$mean\t$median\t$standard_deviation\t$min,$max\n";
