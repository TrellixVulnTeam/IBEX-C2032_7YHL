#!/usr/bin/perl -w

package ReadGene;
require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT = qw/GetGeneInfo Init_count/;

my %utr;
my %chr_strand_of_gene;
my %gene_start;
my %gene_end;
my %biotype;
$biotype{"na"} = "intergenic";
my %intergene_length;
sub GetGeneInfo{
	my ($ENS,$Extend) = @_;
	&FirstInfo($ENS);
	&TreatGene();
	my ($gene_location_ref,$gene_start_of_ref)= &get_intergenic_length($Extend);
	return (\%utr,\%gene_start,\%gene_end,\%biotype,\%intergene_length,$gene_location_ref,$gene_start_of_ref);
}

sub FirstInfo{
	my ($ENS) = @_;
	my $trans_idx = 21;
	if ($ENS =~ /Mus/){
		$trans_idx = 25;
	}

	my %compare;
	open ENS,"zcat $ENS | ";
	while(<ENS>){
		next if $_ =~ /^\#/;
		my ($chr,$source,$type,$start,$end,$srd,$info) = (split  /\t/)[0,1,2,3,4,6,8];
		my %info;
		for $item (split /\;/,$info){
			$item =~ s/^\ //g;
			my ($key,$val) = split /\ /,$item;
			$key =~ s/biotype/type/g;
			$info{$key} = $val;
		}

		if($chr !~ /chr/){
			$chr = "chr$chr";
		}
		if($type eq "gene"){
			#my ($gene_id,$gene_name,$gene_type) = (split /\ /,$info)[1,5,9];
			my $gene_id = $info{'gene_id'};
			my $gene_name = $info{'gene_name'};
			my $gene_type = $info{'gene_type'};
			$gene_id =~ s/\"|\;//g;
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
			if (exists $biotype{$gene_name}){
				######Duplicate gene name
				if(abs($end-$start)<abs($gene_end{$chr_strand_of_gene{$gene_name}}->{$gene_name}-$gene_start{$chr_strand_of_gene{$gene_name}}->{$gene_name})){
					#print "delete duplicate gene $gene_id,$gene_name,$start,$end\n";
					next;
				}
			}

			$biotype{$gene_name} = $gene_type;
			if($gene_name eq "LINC01830"){
				print "add gene start $gene_name\n";
			}
			$gene_start{"$chr:$srd"}->{$gene_name} = $start;
			$gene_end{"$chr:$srd"}->{$gene_name} = $end;
			if ($srd eq "-"){
				$gene_start{"$chr:$srd"}->{$gene_name} = $end;
				$gene_end{"$chr:$srd"}->{$gene_name} = $start;
			}
			$chr_strand_of_gene{$gene_name} = "$chr:$srd";
		}
		elsif($type eq "exon"){
			#my ($gene_name,$trans_type) = (split /\ /,$info)[11,$trans_idx]; #mouse 33 human29
			my $gene_name = $info{'gene_name'};
			my $trans_type = $info{'transcript_type'};
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
}

sub TreatGene{
	foreach my $gene_name (keys %biotype){
		if (! exists $utr{$gene_name} && $gene_name ne "na"){
			&Delete_Gene($chr_strand_of_gene{$gene_name},$gene_name);
		}
	}
	my $num_of_utr = keys %utr;
	print "number of gene before  merging overlap last exon $num_of_utr\n";
####Fixed shared exon problems;
	#&Treat_Shared_Exon();
	$num_of_utr = keys %utr;
	print "number of gene after merging overlap last exon $num_of_utr\n";
}

sub Delete_Gene{
	my ($chr_strand,$gene_name) = @_;
	if($gene_name eq "LINC01830"){
		print "$gene_name has been deleted\n";
	}
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

sub get_intergenic_length{
	my ($Extend) = @_;
	my ($gene_location_ref,$gene_start_of_ref) = &Sort_gene();
	while(my ($location,$gene) = each %$gene_location_ref){
		my $sign = 1;
		$sign = -1 if $location =~ /-/;
		for(my $i=0;$i<@$gene-1;$i++){
			my $gene1 = $gene->[$i];
			my $gene2 = $gene->[$i+1];
			my $gene1_start = $gene_start{$location}->{$gene1};
			my $gene1_end   = $gene_end{$location}->{$gene1};
			my $gene2_start = $gene_start{$location}->{$gene2};
			if(!defined $gene2_start){
				print "$location,$gene2\n";
			}
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
	return ($gene_location_ref,$gene_start_of_ref);
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

sub Init_count{
	my ($gene_location_ref) = @_;
	my %count_for;
	while(my ($location,$gene) = each %$gene_location_ref){
		$count_for{$location} = 0;
	}
	return (\%count_for);
}

1;
