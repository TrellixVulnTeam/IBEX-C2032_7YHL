#!/usr/bin/perl -w
#
#Yongakng Long 2020/02/02 fixed filter gene option
#2020/02/03 fixed some exon shared by multiple genes.
##To be fixed, intergene length

my ($data,$inp,$out,$ENS) = @ARGV;

my $Extend = 10000;  ###Maximum extension: 10k;
my $Inter_extend = 10000; #####Maximum inter gene extension;
my $Window = 25;   ###Window size for predict


my %compare;
my %utr;
my %chr_strand_of_gene;
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
		#next if $gene_type ne "protein_coding";
		next if $gene_type =~ /s.*RNA/; #snoRNA,scRNA,snRNA
		next if $gene_type eq "miRNA";
		next if $gene_type eq "TEC";
		next if $gene_type =~ /misc.*RNA/ ; #misc RNA
		next if $gene_type =~ /rRNA/;
		next if $gene_type =~ /IG_.*/;
		next if $gene_type =~ /ribozyme/;
		$biotype{$gene_name} = $gene_type;
		$gene_start{"$chr:$srd"}->{$gene_name} = $start;
		$gene_end{"$chr:$srd"}->{$gene_name} = $end;
		if ($srd eq "-"){
			$gene_start{"$chr:$srd"}->{$gene_name} = $end;
			$gene_end{"$chr:$srd"}->{$gene_name} = $start;
		}
		$chr_strand_of_gene{$gene_name} = "$chr:$srd";
	}
	elsif($type eq "exon"){
		my ($gene_name,$trans_type) = (split)[19,33]; #mouse 33 human29
		$gene_name =~ s/\"|\;//g;
		$trans_type =~ s/\"|\;//g;
		next if ! exists $biotype{$gene_name};
		if($srd eq "+"){
			if(!exists $compare{$gene_name} || $compare{$gene_name} < $end){
				if($trans_type eq "protein_coding" || $biotype{$gene_name} ne "protein_coding"){
					$compare{$gene_name} = $end;
					$utr{$gene_name} = "$start-$end";
					$gene_end{"$chr:$srd"}->{$gene_name} = $end;
				}
			}
		}
		else{
			if(!exists $compare{$gene_name} || $compare{$gene_name} > $start){
				if($trans_type eq "protein_coding" || $biotype{$gene_name} ne "protein_coding"){
					$compare{$gene_name} = $start;
					$utr{$gene_name} = "$end-$start";
					$gene_end{"$chr:$srd"}->{$gene_name} = $start;
				}
			}
		}
	}
}

foreach my $gene_name (keys %biotype){
	if (! exists $utr{$gene_name}){
		&Delete_Gene($chr_strand_of_gene{$gene_name},$gene_name);
	}
}


my $num_of_utr = keys %utr;
print "number of gene before  merging overlap last exon $num_of_utr\n";
####Fixed shared exon problems;
&Treat_Shared_Exon();
$num_of_utr = keys %utr;
print "number of gene after merging overlap last exon $num_of_utr\n";

=pod
if(exists $utr{"OSBPL9"}){
	print "exotsts\n";
}
else{
	print "not exitsts\n";
}
=cut

my ($gene_location_ref,$gene_start_of_ref) = &Sort_gene();

my %intergene_length;
my %count_for;
while(my ($location,$gene) = each %$gene_location_ref){
	my $sign = 1;
	$sign = -1 if $location =~ /-/;
	$count_for{$location} = 0;
	for(my $i=0;$i<@$gene-1;$i++){
		my $gene1 = $gene->[$i];
		my $gene2 = $gene->[$i+1];
		my $gene1_start = $gene_start{$location}->{$gene1};
		my $gene1_end   = $gene_end{$location}->{$gene1};
		my $gene2_start = $gene_start{$location}->{$gene2};
		my $gene2_end   = $gene_end{$location}->{$gene2};
		my $intergene_length = ($gene2_start-$gene1_end)*$sign;
		if($intergene_length < 0){ ###Overlap gene
			if($biotype{$gene1} eq "protein_coding"){
				my ($utr2_start,$utr2_end) = split /\-/,$utr{$gene2};
				$intergene_length = ($utr2_start-$gene1_end)*$sign;
				if($intergene_length<0){
					$intergene_length = $Extend;
				}
			}
			else{
				$intergene_length = 0;
			}
		}
		my $gene_length = ($gene1_end - $gene1_start)*$sign;
		$intergene_length = $gene_length if $intergene_length > $gene_length;
		$intergene_length{$gene1} = $intergene_length;
	}
	$intergene_length{$gene->[@$gene-1]} = $Extend;  ###Last Annotated gene
}


my %valid_pas;
open FILE,"sort -k2,2 -k6,6 -k5,5n $inp |";
my $header = <FILE>;
my @INP = <FILE>;
foreach(@INP){
	chomp;
	my ($pas_id,$chr,$pos,$strand,$rep1,$rep2) = (split)[0,1,4,5,6,7];
	my $ave = ($rep1+$rep2)/2;
	next if $ave <= 0;
	$valid_pas{$pas_id} = '';
}

my %pas_gene;
my %pas_type;
my %filter;
my %symbol_of;
my %remark;
my @remain_plus;
open FILE,"awk '(\$5 == \"+\")' $data | sort -k 3,3 -k 4,4n | ";
while(<FILE>){
	chomp;
	next if $_ =~ /^pas_id/;
	my @data = split /\t/;
	my $pas_id = $data[0];
	next if !exists $valid_pas{$pas_id};
	&Assign_pAs_To_Gene(\@data,1);
}

my @remain_minus;
open FILE,"awk '(\$5 == \"-\")' $data | sort -k 3,3 -k 4,4nr | ";
while(<FILE>){
	chomp;
	next if $_ =~ /^pas_id/;
	my @data = split /\t/;
	my $pas_id = $data[0];
	next if !exists $valid_pas{$pas_id};
	&Assign_pAs_To_Gene(\@data,-1);
}


my %total;
foreach(@INP){
	chomp;
	my ($pas_id,$chr,$pos,$strand,$rep1,$rep2) = (split)[0,1,4,5,6,7];
	my $ave = ($rep1+$rep2);
	next if $ave <= 0;
	my $symbol = $pas_gene{$pas_id};
	$total{$symbol} += $ave;
}



open OUT,">$out";
print OUT "pas_id\tpas_type\tchr\tposition\tstrand\tsymbol\tusage\treadCount\tmotif\tave_diff\n";
foreach(@INP){
	chomp;
	next if $_ =~ /^pas_id/;
	my ($pas_id,$chr,$pos,$strand,$rep1,$rep2) = (split)[0,1,4,5,6,7];
	my $ave = ($rep1+$rep2);
	next if $ave <=0;
	my $symbol = $symbol_of{$pas_id};
	my $new_symbol = $pas_gene{$pas_id};
	next if !exists $total{$new_symbol} || $total{$new_symbol} == 0;
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
	my $ave = $count>20 ? $sum/$count : 0;
	return $ave;
}
sub Delete_Gene{
	my ($chr_strand,$gene_name) = @_;
	delete $utr{$gene_name};
	delete $gene_start{$chr_strand}->{$gene_name};
	delete $gene_end{$chr_strand}->{$gene_name};
}

sub Determin_Delete_Gene{
	###Delete gene name with more number
	my ($chr_strand,$gene_name,$gene_name_ori) = @_;
	my $count = () = $gene_name =~ /\d/g;
	my $count_ori = () = $gene_name_ori =~ /\d/g;
	if($count>$count_ori){
		&Delete_Gene($chr_strand,$gene_name);
	}
	elsif($count==$count_ori){
		if(length($gene_name)>length($gene_name_ori)){
			&Delete_Gene($chr_strand,$gene_name);
		}
		else{
			&Delete_Gene($chr_strand,$gene_name_ori);
		}
	}
	else{
		&Delete_Gene($chr_strand,$gene_name_ori);
	}
}

sub Assign_pas_type{
	my ($pas_type) = @_;
	my $new_pas_type;
	if($pas_type =~ /3.*UTR/){
		$new_pas_type = "LE";
	}
	elsif($pas_type eq "CDS" || $pas_type eq "Intron"){
		$new_pas_type = "UR";
	}
	else{
		$new_pas_type = "ncRNA";
	}
	return $new_pas_type;
}

sub Treat_Shared_Exon{
	my %start_repeat_check;
	my %end_repeat_check;
	while (my ($gene_name,$region) = each %utr){
		my ($start,$end) = split /\-/,$region;
		my $chr_strand = $chr_strand_of_gene{$gene_name};
		if($chr_strand =~ /-/){
			my $tmp = $end;
			$end = $start;
			$start = $tmp;
		}
		if (exists $start_repeat_check{"$chr_strand-$start"}){
			my ($gene_name_ori,$end_ori) = @{$start_repeat_check{"$chr_strand-$start"}};
			my $diff = $end_ori - $end;
			if($biotype{$gene_name} eq "protein_coding" && $biotype{$gene_name_ori} ne "protein_coding"){
				$start_repeat_check{"$chr_strand-$start"} = [$gene_name,$end];
				&Delete_Gene($chr_strand,$gene_name_ori);
				
			}
			elsif($biotype{$gene_name} ne "protein_coding" && $biotype{$gene_name_ori} eq "protein_coding"){
				&Delete_Gene($chr_strand,$gene_name);
			}
			elsif ($diff<0){
				$start_repeat_check{"$chr_strand-$start"} = [$gene_name,$end];
				&Delete_Gene($chr_strand,$gene_name_ori);
			}
			elsif($diff==0){
				&Determin_Delete_Gene($chr_strand,$gene_name,$gene_name_ori);
			}
			else{
				&Delete_Gene($chr_strand,$gene_name);
			}
		}
		else{
			$start_repeat_check{"$chr_strand-$start"} = [$gene_name,$end];
		}
		if (exists $end_repeat_check{"$chr_strand-$end"}){
			my ($gene_name_ori,$start_ori) = @{$end_repeat_check{"$chr_strand-$end"}};
			my $diff = $start_ori - $start;
			if($biotype{$gene_name} eq "protein_coding" && $biotype{$gene_name_ori} ne "protein_coding"){
				$end_repeat_check{"$chr_strand-$end"} = [$gene_name,$start];
				&Delete_Gene($chr_strand,$gene_name_ori);
				
			}
			elsif($biotype{$gene_name} ne "protein_coding" && $biotype{$gene_name_ori} eq "protein_coding"){
				&Delete_Gene($chr_strand,$gene_name);
			}
			elsif ($diff>0){
				$end_repeat_check{"$chr_strand-$end"} = [$gene_name,$start];
				&Delete_Gene($chr_strand,$gene_name_ori);
			}
			elsif($diff==0){
				&Determin_Delete_Gene($chr_strand,$gene_name,$gene_name_ori);
			}
			else{
				&Delete_Gene($chr_strand,$gene_name);
			}
		}
		else{
			$end_repeat_check{"$chr_strand-$end"} = [$gene_name,$start];
		}
	}
}

sub Sort_gene{
	my %gene_location;
	my %gene_start_of;
	while(my ($location,$val) = each %gene_end){
		if($location =~ /\+/){
			foreach my $key (sort{$val->{$a} <=> $val->{$b}} keys %$val){
				push @{$gene_location{$location}},$key;
			}
		}
		elsif($location =~ /\-/){
			foreach my $key (sort{$val->{$b} <=> $val->{$a}} keys %$val){
				push @{$gene_location{$location}},$key;
			}
		}
	}
	while(my ($location,$val) = each %gene_start){
		if($location =~ /\+/){
			foreach my $key (sort{$val->{$a} <=> $val->{$b}} keys %$val){
				push @{$gene_start_of{$location}},$key;
			}
		}
		elsif($location =~ /\-/){
			foreach my $key (sort{$val->{$b} <=> $val->{$a}} keys %$val){
				push @{$gene_start_of{$location}},$key;
			}
		}
	}
	return (\%gene_location,\%gene_start_of);
}


sub Assign_pAs_To_Gene{
	my ($data_ref,$sign) = @_;
	my @data = @$data_ref;
	my $before = &TrimmedMean(@data[8..108]);
	my $after = &TrimmedMean(@data[109..$#data]);
	return if $before <= 0;
	my ($pas_id,$pas_type,$chr,$pos,$strand,$symbol,$motif) = @data[0..6];
	my $new_pas_type = "intergenic";
	my $new_symbol = "na";
	my $extend_length = "No";
	my $val = $gene_start{"$chr:$strand"};
	my $val2 = $gene_end{"$chr:$strand"};
	my $sort_genes_ref = $gene_start_of_ref->{"$chr:$strand"};
	my $between_gene = "inter_$sort_genes_ref->[0]";

	for(my $i=$count_for{"$chr:$strand"};$i<@$sort_genes_ref;$i++){
		my $gene_name = $sort_genes_ref->[$i];
		my $start = $val->{$gene_name};
		my $end =  $val2->{$gene_name};
		my $ext_start = $start;
		my $ext_end   = $end;
		my $extend  = $Extend;
		$extend = $intergene_length{$gene_name} if  $extend > $intergene_length{$gene_name};
		$extend = $Window if $extend < $Window;
		$ext_end += $sign*$extend;

		if($ext_start*$sign > $pos*$sign){
			last;
		}
		elsif($ext_end*$sign >= $pos*$sign){
			$new_symbol = $gene_name;
			my ($utr_start,$utr_end) = split /\-/,$utr{$gene_name};
			if($utr_start*$sign <= $pos*$sign){
				$new_pas_type = "LE";
				$extend_length = ($pos - $end)*$sign if ($pos-$end)*$sign>0;
			}
			else{
				$new_pas_type = "UR";
				for(my $j=$i+1;$j<$i+60 && $j < @$sort_genes_ref;$j++){
					my $new_gene_name = $sort_genes_ref->[$j];
					next if $biotype{$new_gene_name} ne "protein_coding";
					my ($new_utr_start,$new_utr_end) = split /\-/,$utr{$new_gene_name};
					my $new_start = $val->{$new_gene_name};
					my $new_extend = $intergene_length{$new_gene_name};
					$new_extend = ($utr_start-$new_utr_end)*$sign if $new_extend>($utr_start-$new_utr_end)*$sign;
					$new_extend = $Inter_extend if $new_extend > $Inter_extend;
					$new_extend = $Window if $new_extend < $Window;
					$utr_ext_end = $new_utr_end +  $new_extend*$sign;
					if($new_utr_start*$sign <= $pos*$sign && $utr_ext_end*$sign >= $pos*$sign){
						$new_pas_type = "LE";
						$new_symbol = $new_gene_name;
						$extend_length = ($pos-$utr_end)*$sign if ($pos-$utr_end)*$sign>0;
						last;
					}
					elsif($new_start*$sign <= $pos*$sign && $new_utr_start*$sign > $pos*$sign && $new_utr_end*$sign <= $utr_start*$sign){
						$new_pas_type = "UR";
						$new_symbol = $new_gene_name;
						last;
					}
					elsif($new_utr_end*$sign > $utr_start*$sign){
						last;
					}
				}
			}
			last;
		}
		$count_for{"$chr:$strand"} = $i;
		if($i+1 < @$sort_genes_ref){
			$between_gene = "inter_$sort_genes_ref->[$i]_$sort_genes_ref->[$i+1]";
		}
		else{
			$between_gene = "inter_$sort_genes_ref->[$i]_";
		}
	}
	$biotype{$between_gene} = 'intergenic';
	if($new_symbol eq "na"){
		$new_symbol = $between_gene;
		if(exists $utr{$symbol}){
			my ($utr_start2,$utr_end2) = split /\-/,$utr{$symbol};
			$new_pas_type = &Assign_pas_type($pas_type);
			$new_symbol = $symbol;
			$extend_length = ($pos-$utr_end2)*$sign if ($pos-$utr_end2)*$sign>0;
		}
	}
	elsif($biotype{$new_symbol} ne "protein_coding"){
		$new_pas_type = "ncRNA";
	}
	my $ave = ($before+$after)/2;
	my $diff = $before-$after;
	my $ave_diff = $diff/$ave;
	$pas_type{$pas_id} = "$pas_type\t$chr\t$pos\t$strand\t$symbol";
	$filter{$pas_id} = "$motif\t$ave_diff\t$before";
	$symbol_of{$pas_id} = $symbol;
	$pas_gene{$pas_id}  = $new_symbol;
	$remark{$pas_id} = "$new_symbol\t$new_pas_type\t$extend_length\t$between_gene";
}

sub Init_count{
	while(my ($location,$gene) = each %$gene_location_ref){
		$count_for{$location} = 0;
	}
}
