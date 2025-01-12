#!/usr/bin/perl -w
#
#
#Update 2020/12/22 Yongkang Long
use TrimmedMean;

my ($PAS,$scanTranscriptome,$round,$polyASeqRCThreshold,$RNASeqRCThreshold,$usageThreshold,$Shift) = @ARGV;

my %pas_shift; ####shift of the pas
my %pas_origin; ####origin pasid of the shifted pas;
my %pas_type;   ######pas type of pas;
my %pas_symbol;

open FILE,"$PAS";
<FILE>;
while(<FILE>){
	chomp;
	my ($pas_id,$pas_type,$chr,$end,$srd,$symbol,$usage,$polyASeqRC,undef,undef,$RNASeqRC) = split;
	next if $polyASeqRC <= $polyASeqRCThreshold;
	next if $RNASeqRC   <= $RNASeqRCThreshold;
	next if $usage <=  $usageThreshold;
	my $pos = $end;
	$pas_shift{"$chr:$pos:$srd"}  .= 'Origin';
	$pas_origin{"$chr:$pos:$srd"}  = $pas_id;
	$pas_type{$pas_id} = $pas_type;
	$pas_symbol{$pas_id} = $symbol;
	for (my $i=1;$i<=$Shift;$i++){
		if($srd eq "+"){
			$pos = $end-$i;
		}
		elsif($srd eq "-"){
			$pos = $end+$i;
		}
		else{
			print "Warning. Invalid stranding $srd at pas $pas_id\n";
		}
		$pas_shift{"$chr:$pos:$srd"} .= "Up$i";
		$pas_origin{"$chr:$pos:$srd"}  = $pas_id;

		if($srd eq "+"){
			$pos = $end+$i;
		}
		elsif($srd eq "-"){
			$pos = $end-$i;
		}
		$pas_shift{"$chr:$pos:$srd"} .= "Dn$i";
		$pas_origin{"$chr:$pos:$srd"}  = $pas_id;
	}
}


open FILE,"$scanTranscriptome";
my $header = <FILE>;
($baseName) = (split /\//,$scanTranscriptome)[-1];
$out = "data/positive/$round/$baseName";
open OUT,">$out";
while(<FILE>){
	chomp;
	my @data = split /\t/;
	my $pas_id = $data[0];
	if(exists $pas_shift{$pas_id}){
		my $length = int((@data-8)/2);
		my $before = &TrimmedMean(@data[8..8+$length]);
		next if $before <= $RNASeqRCThreshold;
		my $val = $pas_shift{$pas_id};
		$data[6] = $pas_origin{$pas_id};
		$data[1] = "$data[1]\_$pas_type{$data[6]}_$pas_symbol{$data[6]}";
		$data[5] = $val;
		print OUT join("\t",@data),"\n";
	}
}
