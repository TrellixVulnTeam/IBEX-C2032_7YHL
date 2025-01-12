#!/usr/bin/perl -w
#
#Yongakng Long 2020/12/22

my ($data,$inp,$out,$ENS) = @ARGV;



my $Extend = 10000;  ###Maximum extension: 10k;
my $Inter_extend = 3000; #####Maximum inter gene extension;
my $Window = 25;   ###Window size for predict


my %compare;
my %utr;
my %gene_start;
my %gene_end;
my %biotype;
$biotype{"na"} = "intergenic";


open ENS,"zcat $ENS | ";
while(<ENS>){
	next if $_ =~ /^\#/;
	my ($chr,$source,$type,$start,$end,$srd) = (split)[0,1,2,3,4,6];
	$chr = "chr$chr";
	if($type eq "gene"){
		my ($gene_name,$gene_type) = (split)[13,17];
		$gene_name =~ s/\"|\;//g;
		$gene_type =~ s/\"|\;//g;
		$biotype{$gene_name} = $gene_type;
		next if $gene_type eq "snoRNA";
		next if $gene_type eq "miRNA";
		next if $gene_type eq "TEC";
		$gene_start{"$chr:$srd"}->{$gene_name} = $start;
		$gene_end{"$chr:$srd"}->{$gene_name} = $end;
	}
	elsif($type eq "exon"){
		my ($gene_name) = (split)[19];
		$gene_name =~ s/\"|\;//g;
		if($srd eq "+"){
			if(!exists $compare{$gene_name}){
				$compare{$gene_name} = $end;
				$utr{$gene_name} = "$start-$end";
			}
			elsif($compare{$gene_name} < $end){
				$compare{$gene_name} = $end;
				$utr{$gene_name} = "$start-$end";
			}
		}
		else{
			if(!exists $compare{$gene_name}){
				$compare{$gene_name} = $start;
				$utr{$gene_name} = "$start-$end";
			}
			elsif($compare{$gene_name} > $start){
				$compare{$gene_name} = $start;
				$utr{$gene_name} = "$start-$end";
			}
		}
	}
}

my %intergene_length;
my %gene_location_plus;
while(my ($location,$val) = each %gene_end){
	if($location =~ /\+/){
		foreach my $key (sort{$val->{$a} <=> $val->{$b}} keys %$val){
			push @{$gene_location_plus{$location}},$key;
		}
	}
}
my %gene_start_of_plus;
while(my ($location,$val) = each %gene_start){
	if($location =~ /\+/){
		foreach my $key (sort{$val->{$a} <=> $val->{$b}} keys %$val){
			push @{$gene_start_of_plus{$location}},$key;
		}
	}
}

while(my ($location,$gene) = each %gene_location_plus){
	for(my $i=0;$i<@$gene-1;$i++){
		my $gene1 = $gene->[$i];
		my $gene2 = $gene->[$i+1];
		my $gene1_start = $gene_start{$location}->{$gene1};
		my $gene1_end   = $gene_end{$location}->{$gene1};
		my $gene2_start = $gene_start{$location}->{$gene2};
		my $gene2_end   = $gene_end{$location}->{$gene2};
		my $intergene_length = $gene2_start-$gene1_end;
		if($intergene_length < 0){ ###Overlap gene
			if($gene2_start <= $gene1_start){
				my ($utr2_start,$utr2_end) = split /\-/,$utr{$gene2};
				$intergene_length = $utr2_start-$gene1_end;
			}
			else{
				if($biotype{$gene2} ne "protein_coding"){
					#$intergene_length = 
					#$gene_start{$location}->{$gene->[$i+2]} - $gene1_end;;
				}
				elsif($biotype{$gene1} eq "protein_coding"){
					#print "$gene1:$gene1_start-$gene1_end\t$gene2:$gene2_start-$gene2_end\n";
					#my ($utr2_start,$utr2_end) = split /\-/,$utr{$gene2};
					#$intergene_length = $utr2_start-$gene1_end;
				}
			}
		}
		my $gene_length = $gene1_end - $gene1_start;
		$intergene_length = $gene_length if $intergene_length > $gene_length;
		$intergene_length{$gene1} = $intergene_length;
	}
	$intergene_length{$gene->[@$gene-1]} = $Extend;  ###Last Annotated gene
}


my %gene_location_minus;
while(my ($location,$val) = each %gene_start){
	if($location =~ /\-/){
		foreach my $key (sort{$val->{$b} <=> $val->{$a}} keys %$val){
			push @{$gene_location_minus{$location}},$key;
		}
	}
}

my %gene_start_of_minus;
while(my ($location,$val) = each %gene_end){
	if($location =~ /\-/){
		foreach my $key (sort{$val->{$b} <=> $val->{$a}} keys %$val){
			push @{$gene_start_of_minus{$location}},$key;
		}
	}
}


while(my ($location,$gene) = each %gene_location_minus){
	for(my $i=0;$i<@$gene-1;$i++){
		my $gene1 = $gene->[$i];
		my $gene2 = $gene->[$i+1];
		my $gene1_start = $gene_start{$location}->{$gene1};
		my $gene1_end   = $gene_end{$location}->{$gene1};
		my $gene2_start = $gene_start{$location}->{$gene2};
		my $gene2_end   = $gene_end{$location}->{$gene2};
		my $intergene_length = $gene1_start-$gene2_end;
		if($intergene_length < 0){ ###Overlap gene
			if($gene2_end >= $gene1_end){  #####Includes
				my ($utr2_start,$utr2_end) = split /\-/,$utr{$gene2};
				$intergene_length = $gene1_start-$utr2_end;
			}
			else{   #####Partially overlap
				if($biotype{$gene2} ne "protein_coding"){
					#$intergene_length = 
					#$gene1_start-$gene_end{$location}->{$gene->[$i+2]};
				}
				elsif($biotype{$gene1} eq "protein_coding"){
					#my ($utr2_start,$utr2_end) = split /\-/,$utr{$gene2};
					#$intergene_length =  $gene1_start-$utr2_end;;
				}
			}
		}
		my $gene_length = $gene1_end - $gene1_start;
		$intergene_length = $gene_length if $intergene_length > $gene_length;
		$intergene_length{$gene1} = $intergene_length;
	}
	$intergene_length{$gene->[@$gene-1]} = $Extend;   #######Last Annotated gene
}

my %pas_gene;
my %pas_type;
my %filter;
my %symbol_of;
my %remark;
my %count_for;
#open FILE,"$data";
open FILE,"awk '(\$5 == \"+\")' $data | sort -k 3,3 -k 4,4n | ";
while(<FILE>){
	chomp;
	next if $_ =~ /^pas_id/;
	my ($pas_id,$pas_type,$chr,$pos,$strand,$symbol,$motif) = split;
	my $new_pas_type = "intergenic";
	my $new_symbol = "na";
	my $extend_length = "No";
	my $val = $gene_start{"$chr:$strand"};
	my $val2 = $gene_end{"$chr:$strand"};
	my $sort_genes_ref = $gene_start_of_plus{"$chr:$strand"};
	$count_for{"$chr:$strand"} = 0;
	my $between_gene = "inter_$sort_genes_ref->[0]";

	#foreach my $gene_name (keys %$val){
	for(my $i=$count_for{"$chr:$strand"};$i<@$sort_genes_ref;$i++){
		my $gene_name = $sort_genes_ref->[$i];
		my $start = $val->{$gene_name};
		my $end =  $val2->{$gene_name};
		my $ext_start = $start;
		my $ext_end   = $end;
		my $extend  = $Extend;
		$extend = $intergene_length{$gene_name} if  $extend > $intergene_length{$gene_name};
		$extend = $Window if $extend < $Window;
		$ext_end += $extend;

		if($ext_start > $pos){
			last;
		}
		elsif($ext_end >= $pos){
			$new_symbol = $gene_name;
			my ($utr_start,$utr_end) = split /\-/,$utr{$gene_name};
			$extend_length = $pos - $end if $pos-$end>0;
			if($utr_start <= $pos){
				$new_pas_type = "LE";
			}
			else{
				$new_pas_type = "UR";
				for(my $j=$count_for{"$chr:$strand"}+1;
					$j<$count_for{"$chr:$strand"}+60 && $j < @$sort_genes_ref;
					$j++){
					my $new_gene_name = $sort_genes_ref->[$j];
					#next if $biotype{$new_gene_name} ne "protein_coding";
					my ($new_utr_start,$new_utr_end) = split /\-/,$utr{$new_gene_name};
					my $new_extend = $intergene_length{$new_gene_name};
					$new_extend = $Inter_extend if $new_extend > $Inter_extend;
					$new_extend = $Window if $new_extend < $Window;
					$utr_ext_end = $new_utr_end +  $new_extend;
					if($new_utr_start <= $pos &&  $utr_ext_end >= $pos){
						if(exists $utr{$symbol}){
							my ($utr_start2,$utr_end2) = split /\-/,$utr{$symbol};
							if($pas_type =~ /UTR/){
								$new_pas_type = "LE";
							}
							else{
								$new_pas_type = "UR";
							}
							$new_symbol = $symbol;
							$extend_length = $pos - $utr_end2 if $pos-$utr_end2>0;
						}
						else{
							$new_pas_type = "Overlap";
							$new_symbol = $new_gene_name;
							$extend_length = $pos - $new_utr_end if $pos-$new_utr_end>0;

						}
						last;
					}
				}
			}
			last;
		}
		$count_for{"$chr:$strand"} = $i;
		$between_gene = "inter_$sort_genes_ref->[$i]_$sort_genes_ref->[$i+1]";
	}
	$biotype{$between_gene} = 'intergenic';
	$new_symbol = $between_gene if $new_symbol eq "na";
	if($new_symbol eq "na"){
		$new_symbol = $between_gene;
		if(exists $utr{$symbol}){
			my ($utr_start2,$utr_end2) = split /\-/,$utr{$symbol};
			if($pas_type =~ /UTR/){
				$new_pas_type = "LE";
			}
			else{
				$new_pas_type = "UR";
			}
			$new_symbol = $symbol;
			$extend_length = $pos - $utr_end2 if $pos-$utr_end2>0;
		}
	}
	elsif($biotype{$new_symbol} ne "protein_coding"){
		$new_pas_type = "ncRNA";
	}
	my @data = split;
	my $before = &TrimmedMean(@data[8..108]);
	my $after = &TrimmedMean(@data[109..$#data]);
	my $ave = ($before+$after)/2;
	my $diff = $before-$after;
	my $ave_diff = $diff/$ave;
	$pas_type{$pas_id} = "$pas_type\t$chr\t$pos\t$strand\t$symbol";
	$filter{$pas_id} = "$motif\t$ave_diff\t$before";
	$symbol_of{$pas_id} = $symbol;
	$pas_gene{$pas_id}  = $new_symbol;
	$remark{$pas_id} = "$new_symbol\t$new_pas_type\t$extend_length\t$between_gene";
}



open FILE,"awk '(\$5 == \"-\")' $data | sort -k 3,3 -k 4,4nr | ";
while(<FILE>){
	chomp;
	next if $_ =~ /^pas_id/;
	my ($pas_id,$pas_type,$chr,$pos,$strand,$symbol,$motif) = split;
	my $new_pas_type = "intergenic";
	my $new_symbol = "na";
	my $extend_length = "No";
	my $val = $gene_start{"$chr:$strand"};
	my $val2 = $gene_end{"$chr:$strand"};
	my $sort_genes_ref = $gene_start_of_minus{"$chr:$strand"};
	$count_for{"$chr:$strand"} = 0;

	my $between_gene = "inter_$sort_genes_ref->[0]";

	#foreach my $gene_name (keys %$val){
	for(my $i=$count_for{"$chr:$strand"};$i<@$sort_genes_ref;$i++){
		my $gene_name = $sort_genes_ref->[$i];
		my $start = $val->{$gene_name};
		my $end =  $val2->{$gene_name};
		my $ext_start = $start;
		my $ext_end   = $end;
		my $extend  = $Extend;
		$extend = $intergene_length{$gene_name} if $intergene_length{$gene_name} < $Extend;
		$extend = $Window if $extend < $Window;
		$ext_start -= $extend;
		if($ext_end < $pos){
			last;
		}
		elsif($ext_start <= $pos){
			$new_symbol = $gene_name;
			my ($utr_start,$utr_end) = split /\-/,$utr{$gene_name};
			$extend_length = $start-$pos if $start-$pos>0;
			if($utr_end >= $pos){
				$new_pas_type = "LE";
			}
			else{
				$new_pas_type = "UR";
				for(my $j=$count_for{"$chr:$strand"}+1;
					$j<$count_for{"$chr:$strand"}+60 && $j < @$sort_genes_ref;
					$j++){
					my $new_gene_name = $sort_genes_ref->[$j];
					my ($new_utr_start,$new_utr_end) = split /\-/,$utr{$new_gene_name};
					my $new_extend = $intergene_length{$new_gene_name};
					$new_extend = $Inter_extend if $new_extend > $Inter_extend;
					$new_extend = $Window if $new_extend < $Window;
					$utr_ext_start = $new_utr_start -  $new_extend;
					if($new_utr_end >= $pos &&  $utr_ext_start <= $pos){
						if(exists $utr{$symbol}){
							my ($utr_start2,$utr_end2) = split /\-/,$utr{$symbol};
							if($pas_type =~ /UTR/){
								$new_pas_type = "LE";
							}
							else{
								$new_pas_type = "UR";
							}
							$new_symbol = $symbol;
							$extend_length = $utr_start2-$pos if $utr_start2-$pos>0;
						}
						else{
							$new_pas_type = "Overlap";
							$new_symbol = $new_gene_name;
							$extend_length = $new_utr_start - $pos if $new_utr_start - $pos > 0;
						}

						last;
					}
				}
			}
			last;
		}
		$count_for{"$chr:$strand"} = $i;
		$between_gene = "inter_$sort_genes_ref->[$i]_$sort_genes_ref->[$i+1]";
	}
	$biotype{$between_gene} = 'intergenic';
	if($new_symbol eq "na"){
		$new_symbol = $between_gene;
		if(exists $utr{$symbol}){
			my ($utr_start2,$utr_end2) = split /\-/,$utr{$symbol};
			if($pas_type =~ /UTR/){
				$new_pas_type = "LE";
			}
			else{
				$new_pas_type = "UR";
			}
			$new_symbol = $symbol;
			$extend_length = $utr_start2-$pos if $utr_start2-$pos>0;
		}
	}
	elsif($biotype{$new_symbol} ne "protein_coding"){
		$new_pas_type = "ncRNA";
	}
	my @data = split;
	my $before = &TrimmedMean(@data[8..108]);
	my $after = &TrimmedMean(@data[109..$#data]);
	my $ave = ($before+$after)/2;
	my $diff = $before-$after;
	my $ave_diff = $diff/$ave;
	$pas_type{$pas_id} = "$pas_type\t$chr\t$pos\t$strand\t$symbol";
	$filter{$pas_id} = "$motif\t$ave_diff\t$before";
	$symbol_of{$pas_id} = $symbol;
	$pas_gene{$pas_id}  = $new_symbol;
	$remark{$pas_id} = "$new_symbol\t$new_pas_type\t$extend_length\t$between_gene";
}


open FILE,"$inp";
<FILE>;
my %total;
while(<FILE>){
	chomp;
	my ($pas_id,$chr,$pos,$strand,$rep1,$rep2) = (split)[0,1,4,5,6,7];
	my $ave = ($rep1+$rep2)/2;
	next if $ave <= 5;
	my $symbol = $pas_gene{$pas_id};
	$total{$symbol} += $ave;
}



open INP,"$inp";
open OUT,">$out";
print OUT "pas_id\tpas_type\tchr\tposition\tstrand\tsymbol\tusage\treadCount\tmotif\tave_diff\n";
while(<INP>){
	chomp;
	next if $_ =~ /^pas_id/;
	my ($pas_id,$chr,$pos,$strand,$rep1,$rep2) = (split)[0,1,4,5,6,7];
	#next if $strand eq "-";
	my $ave = ($rep1+$rep2)/2;
	next if $ave <=5;
	#next if $pas_id =~ /na/;
	#next if $pas_id =~ /NO/;
	#next if !exists $pas_type{"$chr:$pos:$strand"};
	my $symbol = $symbol_of{$pas_id};
	my $new_symbol = $pas_gene{$pas_id};
	#my $usage = $total{$gene_id}>0 ? $ave/$total{$gene_id} : 0;;
	my $usage = $ave/$total{$new_symbol};
	my $remark = $remark{$pas_id};
	my $biotype = $biotype{$new_symbol};
	print OUT "$pas_id\t$pas_type{$pas_id}\t$usage\t$ave\t$filter{$pas_id}\t$remark\t$biotype\n";
}


sub TrimmedMean{
	my @data = @_;
	my $sum = 0;
	my $count = 0;
	foreach my $ele (@data){
		if($ele>0){
			$sum += $ele;
			$count++;
		}
	}
	my $ave = $count>0 ? $sum/$count : 0;
	return $ave;
}
