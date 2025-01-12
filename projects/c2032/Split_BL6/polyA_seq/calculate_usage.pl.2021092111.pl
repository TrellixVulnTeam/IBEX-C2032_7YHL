#!/usr/bin/perl -w
#

use ReadGene;
use Assign;
my $ENS = "/home/longy/cnda/ensembl/Homo_sapiens.GRCh38.103.gtf.gz";
my $data = "callPeakK562_Chen.bed";
open OUT,">usage.K562.pAs.txt";
print OUT "pas_id\tpas_type\tchr\tposition\tstrand\tsymbol\tusage\treadCount\tmotif\tave_diff\n";

my $window  = 24;
my $Extend = 10000;  ###Maximum extension: 10k;
my $Inter_extend = 10000; #####Maximum inter gene extension;
my $Extend_Info = [$Extend,$Inter_extend,$window+1];
my ($utr_ref,$gene_start_ref,$gene_end_ref,$biotype_ref,$intergene_length_ref,$gene_location_ref,$gene_start_of_ref) = &GetGeneInfo($ENS,$Extend);
my $count_for_ref = &Init_count($gene_location_ref);


my %total;
my %usage;
my %info;
my %pas2symbol;



open FILE,"awk '(\$5 == \"+\")' $data | sort -k 3,3 -k 4,4n | ";
while(<FILE>){
	chomp;
	my ($pas_id,undef,$chr,$max_pos,$strand,undef,undef,$total_readCount,$motif,$ave_diff,$coverage,$max_status) = split;
	next if $max_status eq "None" && $total_readCount<10;
	my $sign = 1;
	my ($count,$pas_type,$symbol,$extend_length,$between_gene) = &Assign_pAs_To_Gene($count_for_ref->{"$chr:$strand"},$sign,$max_pos,$Extend_Info,$utr_ref,$gene_start_ref->{"$chr:$strand"},$gene_end_ref->{"$chr:$strand"},$biotype_ref,$gene_start_of_ref->{"$chr:$strand"},$intergene_length_ref);
	$count_for_ref->{"$chr:$strand"} = $count;
	my $biotype = $biotype_ref->{$symbol};

	$total{$symbol} += $total_readCount;
	$usage{$pas_id} = $total_readCount;
	$pas2symbol{$pas_id} = $symbol;
	$info{$pas_id}  =  "$pas_id\t$pas_type\t$chr\t$max_pos\t$strand\t$symbol\tusage\t$total_readCount\t$motif\t$ave_diff\t$coverage\t$biotype\t$extend_length\tNone\t$max_status";
}

open FILE,"awk '(\$5 == \"-\")' $data | sort -k 3,3 -k 4,4nr | ";
while(<FILE>){
	chomp;
	my ($pas_id,undef,$chr,$max_pos,$strand,undef,undef,$total_readCount,$motif,$ave_diff,$coverage,$max_status) = split;
	next if $max_status eq "None" && $total_readCount<10;
	my $sign = -1;
	my ($count,$pas_type,$symbol,$extend_length,$between_gene) = &Assign_pAs_To_Gene($count_for_ref->{"$chr:$strand"},$sign,$max_pos,$Extend_Info,$utr_ref,$gene_start_ref->{"$chr:$strand"},$gene_end_ref->{"$chr:$strand"},$biotype_ref,$gene_start_of_ref->{"$chr:$strand"},$intergene_length_ref);
	$count_for_ref->{"$chr:$strand"} = $count;
	my $biotype = $biotype_ref->{$symbol};

	$total{$symbol} += $total_readCount;
	$usage{$pas_id} = $total_readCount;
	$pas2symbol{$pas_id} = $symbol;
	$info{$pas_id}  =  "$pas_id\t$pas_type\t$chr\t$max_pos\t$strand\t$symbol\tusage\t$total_readCount\t$motif\t$ave_diff\t$coverage\t$biotype\t$extend_length\tNone\t$max_status";
}


while(my ($pas_id,$val) = each %info){
	my $symbol = $pas2symbol{$pas_id};
	my $usage  = $usage{$pas_id}/$total{$symbol};
	my @data = split /\t/,$val;
	$data[6] = $usage;
	print OUT join("\t",@data),"\n";
}

