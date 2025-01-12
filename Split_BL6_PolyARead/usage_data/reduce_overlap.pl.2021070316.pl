#!/usr/bin/perl -w
#
#2021/01/24 Fixed bugs. usage files should be sorted.
my $dist_threshold = 49;

=pod
my $usage = "../../Split_BL6/polyA_seq/bl6_rep1.pAs.usage.txt";
my $out = "bl6_rep1.pAs.usage.txt";
my $db = "/home/longy/workspace/apa_predict/pas_dataset/bl6.pAs.tianbin.txt";
my $COV = "bl6_rep1.pAs.coverage.txt";
=cut
#=pod
my $usage = "/home/longy/project/Split_BL6/polyA_seq/snu398_control.pAs.usage.txt";
my $out = "snu398_control.pAs.usage.txt";
my $db = "/home/longy/workspace/apa_predict/pas_dataset/hg38.pAs.tianbin.txt";
my $COV = "snu398_control.pAs.merge.coverage.txt";
#my $COV2 = "snu398_control.pAs.ens.coverage.txt";
#my $COV3 = "snu398_control.pAs.coverage.all.txt";
#=cut

open DB,$db;
<DB>;
my %ConserveOf;
while(<DB>){
	chomp;
	my ($pas_id,$conserve) = (split /\t/)[0,-1];
	$ConserveOf{$pas_id} = $conserve;
}

my %hasArich;
&Arich($COV);
#&Arich($COV2);
#&Arich($COV3);

sub Arich{
	my ($COV) = @_;
	open FILE,$COV;
	while(<FILE>){
		chomp;
		my ($pas_id,$sequence) = (split)[0,7];
		my $seq = substr($sequence,int(length($sequence)/2),25);
		if($seq =~ /AAAAAAAAAA/){
			$hasArich{$pas_id} = "Arich";
		}
		else{
			my $count = 0;
			for(my$i=0;$i<length($seq);$i++){
				if(substr($seq,$i,1) eq "A"){
					$count++;
				}
			}
			if($count > 20){
				$hasArich{$pas_id} = "Yes";
			}
			else{
				$hasArich{$pas_id} = "No";
			}
		}
	}
}



open FILE,"sort -k 3,3 -k 5,5 -k 4,4n $usage |";
my $header = <FILE>;
chomp $header;
my @USAGE = <FILE>;
open OUT,">$out";
print OUT "$header\tArich\tConservation\n";
my %dist;
my %readCount;
my %ave_diff;
my %pas_id;
my %remove_id;
foreach(@USAGE){
	chomp;
	my ($pas_id,$pas_type,$chr,$pos,$strand,$symbol,$usage,$readCount,$motif,$ave_diff,$ur,$biotype) = split;
	#next if $hasArich{$pas_id} ne "No" && $ave_diff<1;
	if(exists $dist{$symbol}){
		my $dist_diff = abs($pos - $dist{$symbol});
		if($dist_diff <= $dist_threshold){
			print "$dist_diff\t$readCount\t$readCount{$symbol}\t$pas_id\t$pas_id{$symbol}\n";
			if($readCount > $readCount{$symbol}){
				$remove_id{$pas_id{$symbol}} = '';
			}
			elsif($readCount == $readCount{$symbol}){
				if($ave_diff >= $ave_diff{$symbol}){
					$remove_id{$pas_id{$symbol}} = '';
				}
				else{
					$remove_id{$pas_id} = '';
				}
			}
			else{
				$remove_id{$pas_id} = '';
			}
		}
	}
	$dist{$symbol} = $pos;
	$readCount{$symbol} = $readCount;
	$ave_diff{$symbol} = $ave_diff;
	$pas_id{$symbol} = $pas_id;
}


my %total;
foreach(@USAGE){
	chomp;
	my ($pas_id,$pas_type,$chr,$pos,$strand,$symbol,$usage,$readCount,$motif,$ave_diff) = split;
	#next if $hasArich{$pas_id} ne "No" && $ave_diff<1;
	if(!exists $remove_id{$pas_id}){
		$total{$symbol} += $readCount;
	}
}


my $remove_num = keys %remove_id;
print "$remove_num\n";

foreach(@USAGE){
	chomp;
	my @data = split;
	my ($pas_id,$pas_type,$chr,$pos,$strand,$symbol,$usage,$readCount,$motif,$ave_diff) = split;
	#next if $hasArich{$pas_id} ne "No" && $ave_diff<1;
	if(!exists $remove_id{$data[0]}){
		$data[6] = 0;
		if(exists $total{$data[5]} && $total{$data[5]}>0){
			$data[6] = $data[7]/$total{$data[5]};
		}
		if($data[1] eq "intergenic"){
			#$data[7] /= 5;
			if($data[14] =~ "Diff"){
				$data[7] /= 2;
			}
			else{
				$data[7] /=3;
			}
		}
		elsif($data[1] eq "ncRNA"){
			$data[7] /= 2;
		}
		#print OUT join("\t",@data,$hasArich{$data[0]},$ConserveOf{$data[0]}),"\n";
		print OUT join("\t",@data,$hasArich{$data[0]}),"\n";
	}
}
