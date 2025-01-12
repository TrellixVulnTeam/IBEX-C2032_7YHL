#!/usr/bin/perl -w

use Statistics::Descriptive;

my ($READCOUNT,$OUT) = @ARGV;

my $polyASeqDepth = 0;
my $RNASeqDepth   = 0;
if ($READCOUNT =~ /BL6/){
	#$polyASeqDepth  = 71;
}
elsif($READCOUNT =~ /HepG2/){
	#$polyASeqDepth  = 16;
}

my %polyA_readCount;
my %polyA_totalReadCount;
my %RNA_readCount;
my %RNA_totalReadCount;
my %pas_num;
my %pas_type;
open FILE,"$READCOUNT";
while(<FILE>){
	chomp;
	my ($pas_id,$pas_type,$chr,$pos,$strand,$symbol,$polyAseq,$readCount) = split;
	$polyA_readCount{$symbol}->{$pas_id} = $polyAseq;
	$polyA_totalReadCount{$symbol} += $polyAseq;
	$RNA_readCount{$symbol}->{$pas_id} = $readCount;
	$RNA_totalReadCount{$symbol} += $readCount;
	$pas_num{$symbol}++;
	$pas_type{$pas_id} = $pas_type;
	$RNASeqDepth += $readCount;
	$polyASeqDepth += $polyAseq;
}
print "$RNASeqDepth\n";
$RNASeqDepth /= 1e6;
print "$RNASeqDepth\n";
print "$polyASeqDepth\n";
$polyASeqDepth /= 1e6;
print "$polyASeqDepth\n";


my %polyA_usage;
while(my ($symbol,$val) = each %polyA_readCount){
	my $totalReadCount = $polyA_totalReadCount{$symbol};
	while(my ($pas_id,$readCount) = each %$val){
		if($totalReadCount == 0){
			$polyA_usage{$pas_id} = 0;
		}
		else{
			$polyA_usage{$pas_id} = $val->{$pas_id} / $totalReadCount;
		}
	}
}
my %RNA_usage;
while(my ($symbol,$val) = each %RNA_readCount){
	my $totalReadCount = $RNA_totalReadCount{$symbol};
	while(my ($pas_id,$readCount) = each %$val){
		if($totalReadCount == 0){
			$RNA_usage{$pas_id} = 0;
		}
		else{
			$RNA_usage{$pas_id} = $val->{$pas_id} / $totalReadCount;
		}
	}
}

open OUT,">test";
print OUT "pas_id\tpas_type\tsymbol\tpolyA_readCount\tpolyA_RPM\tlog10polyA_RPM\tRNA_readCount\tRNA_RPM\tlog10RNA_RPM\tpolyA_usage\tRNA_usage\n";
open OUT1,">test1";
print OUT1 "pas_id\tpas_type\tsymbol\tpolyA_readCount\tpolyA_RPM\tlog10polyA_RPM\tRNA_readCount\tRNA_RPM\tlog10RNA_RPM\tpolyA_usage\tRNA_usage\n";
open OUT2,">test2";
print OUT2 "pas_id\tpas_type\tsymbol\tpolyA_readCount\tpolyA_RPM\tlog10polyA_RPM\tRNA_readCount\tRNA_RPM\tlog10RNA_RPM\tpolyA_usage\tRNA_usage\n";
open OUT3,">test3";
print OUT3 "pas_id\tpas_type\tsymbol\tpolyA_readCount\tpolyA_RPM\tlog10polyA_RPM\tRNA_readCount\tRNA_RPM\tlog10RNA_RPM\tpolyA_usage\tRNA_usage\n";
open OUT4,">test4";
print OUT4 "pas_id\tpas_type\tsymbol\tpolyA_readCount\tpolyA_RPM\tlog10polyA_RPM\tRNA_readCount\tRNA_RPM\tlog10RNA_RPM\tpolyA_usage\tRNA_usage\n";
open OUT5,">test5";
print OUT5 "pas_id\tpas_type\tsymbol\tpolyA_readCount\tpolyA_RPM\tlog10polyA_RPM\tRNA_readCount\tRNA_RPM\tlog10RNA_RPM\tpolyA_usage\tRNA_usage\n";
my $n = 0;
my $total  = 0;
my $remove_outlier = 0;
while(my ($symbol,$val) = each %RNA_readCount){
	#next if $pas_num{$symbol} >2;
	while(my ($pas_id,$RNA_readCount) = each %$val){
		if ($RNA_readCount <= 0){
			$n++;
			next;
		}
		my $polyA_readCount = $polyA_readCount{$symbol}->{$pas_id};
		my $polyA_RPM = $polyA_readCount/$polyASeqDepth;
		my $log2polyA_RPM = log($polyA_RPM)/log(10);
		my $RNA_RPM     = $RNA_readCount/$RNASeqDepth;
		my $log2RNA_RPM = log($RNA_RPM)/log(10);

		print OUT "$pas_id\t$pas_type{$pas_id}\t$symbol\t$polyA_readCount\t$polyA_RPM\t$log2polyA_RPM\t$RNA_readCount\t$RNA_RPM\t$log2RNA_RPM\t$polyA_usage{$pas_id}\t$RNA_usage{$pas_id}\n";
		if ($pas_num{$symbol} >1){
			print OUT2 "$pas_id\t$pas_type{$pas_id}\t$symbol\t$polyA_readCount\t$polyA_RPM\t$log2polyA_RPM\t$RNA_readCount\t$RNA_RPM\t$log2RNA_RPM\t$polyA_usage{$pas_id}\t$RNA_usage{$pas_id}\n";
		}
		if ($pas_num{$symbol} <=1){
			print OUT4 "$pas_id\t$pas_type{$pas_id}\t$symbol\t$polyA_readCount\t$polyA_RPM\t$log2polyA_RPM\t$RNA_readCount\t$RNA_RPM\t$log2RNA_RPM\t$polyA_usage{$pas_id}\t$RNA_usage{$pas_id}\n";
		}



		$total++;
		next if $log2polyA_RPM>-1 && $log2RNA_RPM<-2;
		next if $log2polyA_RPM>0 && $log2RNA_RPM<-1;
		next if $log2polyA_RPM>1 && $log2RNA_RPM<0;
		next if $log2polyA_RPM>2 && $log2RNA_RPM<1;
		next if $log2polyA_RPM>3 && $log2RNA_RPM<2;
		#next if $log2polyA_RPM<2 && $log2RNA_RPM>3;
		#next if $log2polyA_RPM<1 && $log2RNA_RPM>2;
		#next if $log2polyA_RPM<0 && $log2RNA_RPM>1;
		#next if $log2polyA_RPM<-1 && $log2RNA_RPM>0;
		#next if $log2polyA_RPM<-2 && $log2RNA_RPM>-1;
		next if $log2polyA_RPM<1 && $log2RNA_RPM>3;
		next if $log2polyA_RPM<0 && $log2RNA_RPM>2;
		$remove_outlier++;

		print OUT1 "$pas_id\t$pas_type{$pas_id}\t$symbol\t$polyA_readCount\t$polyA_RPM\t$log2polyA_RPM\t$RNA_readCount\t$RNA_RPM\t$log2RNA_RPM\t$polyA_usage{$pas_id}\t$RNA_usage{$pas_id}\n";
		if ($pas_num{$symbol} >1){
			print OUT3 "$pas_id\t$pas_type{$pas_id}\t$symbol\t$polyA_readCount\t$polyA_RPM\t$log2polyA_RPM\t$RNA_readCount\t$RNA_RPM\t$log2RNA_RPM\t$polyA_usage{$pas_id}\t$RNA_usage{$pas_id}\n";
		}
		if ($pas_num{$symbol} <=1){
			print OUT5 "$pas_id\t$pas_type{$pas_id}\t$symbol\t$polyA_readCount\t$polyA_RPM\t$log2polyA_RPM\t$RNA_readCount\t$RNA_RPM\t$log2RNA_RPM\t$polyA_usage{$pas_id}\t$RNA_usage{$pas_id}\n";
		}

	}
}

my $outlier = $total-$remove_outlier;
print "remove outlier number: $outlier\n";
print "number: $n\n";
