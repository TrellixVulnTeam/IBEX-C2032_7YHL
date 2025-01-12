#!/usr/bin/perl -w
use List::Util qw(first max maxstr min minstr reduce shuffle sum shuffle) ;
use Assign;
use ReadGene;

my ($ENS,$PAS,$input,$scanGenome,$out2) = @ARGV;
my $Extend = 10000;  ###Maximum extension: 10k;
my $Inter_extend = 10000; #####Maximum inter gene extension;
my $Window = 25;   ###Window size for predict
my $Extend_Info = [$Extend,$Inter_extend,$Window];
print "Start getting gene information\n";
my ($utr_ref,$gene_start_ref,$gene_end_ref,$biotype_ref,$intergene_length_ref,$gene_location_ref,$gene_start_of_ref) = &GetGeneInfo($ENS,$Extend);
print "End getting gene information\n\n";


open FILE,"$input";
<FILE>;
my %predict;
while(<FILE>){
	chomp;
	my ($pos,$id,$diff,$chr,$strand,$gt_pasid,$gt_diff,$db_pasid,$db_diff) = split;
	my $end = sprintf("%.0f",$pos);
	my $pas_id = "$chr:$end:$strand";
	$predict{$pas_id}  = "$gt_diff\t$gt_pasid\t$db_pasid\t$db_diff";
}

my %pas2gene;
open PAS,$PAS;
<PAS>;
while(<PAS>){
	chomp;
	my ($pas_id,$gene_name) = (split)[0,5];
	$pas2gene{$pas_id} = $gene_name;
}

open FILE,"$scanGenome";
my $header  =<FILE>;
open OUT2,">$out2";
while(<FILE>){
	chomp;
	my @data = split;
	my ($pas_id,$motif,$chr,$pos,$strand) =  @data[0..4];
	my $sign = 1;
	$sign = -1 if $strand eq "-";
	if(exists $predict{$data[0]}){
		my (undef,$pas_type,$symbol) = &Assign_pAs_To_Gene(0,$sign,$pos,$Extend_Info,$utr_ref,$gene_start_ref->{"$chr:$strand"},$gene_end_ref->{"$chr:$strand"},$biotype_ref,$gene_start_of_ref->{"$chr:$strand"},$intergene_length_ref);
		my ($gt_diff,$gt_pasid,$db_pasid,$db_diff) = split /\t/, $predict{$data[0]};
		$data[1] .= "_$pas_type\_$symbol";
		$data[6] = "$gt_pasid,$gt_diff,$db_pasid,$db_diff";
		$data[5] = "unassigned";
		if(abs($gt_diff) < 25){
			$data[5] = $pas2gene{$gt_pasid};
		}
		print OUT2 join("\t",@data),"\n";
	}
}
