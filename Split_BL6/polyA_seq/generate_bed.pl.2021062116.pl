#!/usr/bin/perl -w

my ($inp,$output) = @ARGV;
use TrimmedMean;

my $dist_threshold = 37;
open FILE,"awk '(\$5 == \"\+\")' $inp | sort -k 3,3 -k 5,5 -k 4,4nr |";
open OUT,">$output.tmp";
my $previous_pos = 0;
while(<FILE>){
	next if $_ =~ /^pas_id/;
	my ($gene_id,$pas_type,$chr,$pos,$strand) = split;
	my @data = split;
	my $length = int((@data-8)/2);
	my $before = &TrimmedMean(@data[8..8+$length]);
	next if $before <=0;
	my $pre  = $pos-24;
	my $end =  $pos+24; ###12 for end could not extend
	#my $dist_diff = abs($pos - $previous_pos);
	#if($dist_diff < $dist_threshold){
	#	$end = $pos+($dist_diff-24-1);
	#}
	$previous_pos = $pos;
	print OUT "$chr\t$pre\t$end\t$gene_id\t$pos\t$strand\n";
}
open FILE,"awk '(\$5 == \"\-\")' $inp | sort -k 3,3 -k 5,5 -k 4,4n |";
$previous_pos = 0;
while(<FILE>){
	next if $_ =~ /^pas_id/;
	my ($gene_id,$pas_type,$chr,$pos,$strand) = split;
	my @data = split;
	my $length = int((@data-8)/2);
	my $before = &TrimmedMean(@data[8..8+$length]);
	next if $before <= 0;
	my $pre = $pos-24; ##12 for end could not extend
	my $end = $pos+24;
	#my $dist_diff = abs($pos - $previous_pos);
	#if($dist_diff < $dist_threshold){
	#	$pre = $pos-($dist_diff-24-1);
	#}
	$previous_pos = $pos;
	print OUT "$chr\t$pre\t$end\t$gene_id\t$pos\t$strand\n";
}

system("sort -k1,1 -k2,2n -S 30G $output.tmp -o $output");
system("rm $output.tmp");
