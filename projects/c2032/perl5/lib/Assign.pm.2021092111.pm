package Assign;
require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT = qw/Assign_pAs_To_Gene/;

sub Assign_pAs_To_Gene{
	my ($count,$sign,$pos,$Extend_info,$utr_ref,$val,$val2,$biotype_ref,$sort_genes_ref,$intergene_length_ref) = @_;
	my ($Extend,$Inter_extend,$Window) = @$Extend_info;
	my $new_pas_type = "intergenic";
	my $new_symbol = "na";
	my $extend_length = "No";
	my $between_gene = "before_$sort_genes_ref->[0]";

	for(my $i=$count;$i<@$sort_genes_ref;$i++){
	#for(my $i=0;$i<@$sort_genes_ref;$i++){
		my $gene_name = $sort_genes_ref->[$i];
		my $start = $val->{$gene_name};
		my $end =  $val2->{$gene_name};
		my $ext_start = $start;
		my $ext_end   = $end;
		my $extend  = $Extend;
		$extend = $intergene_length_ref->{$gene_name} if  $extend > $intergene_length_ref->{$gene_name};
		$extend = $Window if $extend < $Window;
		$ext_end += $sign*$extend;
		if($ext_start*$sign > $pos*$sign){
			last;
		}
		elsif($ext_end*$sign >= $pos*$sign){
			$count = $i;
			$new_symbol = $gene_name;
			my ($utr_start,$utr_end) = split /\-/,$utr_ref->{$gene_name};
			if($utr_start*$sign <= $pos*$sign){
				$new_pas_type = "LE";
				$extend_length = ($pos - $end)*$sign if ($pos-$end)*$sign>0;
			}
			else{
				$new_pas_type = "UR";
				for(my $j=$i+1;$j<$i+60 && $j < @$sort_genes_ref;$j++){
					my $new_gene_name = $sort_genes_ref->[$j];
					next if $biotype_ref->{$new_gene_name} ne "protein_coding";
					my ($new_utr_start,$new_utr_end) = split /\-/,$utr_ref->{$new_gene_name};
					my $new_start = $val->{$new_gene_name};
					my $new_extend = $intergene_length_ref->{$new_gene_name};
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
	}
	if($count+1 < @$sort_genes_ref){
		$between_gene = "inter_$sort_genes_ref->[$count]_$sort_genes_ref->[$count+1]";
	}
	else{
		$between_gene = "After_$sort_genes_ref->[$count]";
	}
	$biotype_ref->{$between_gene} = 'intergenic';
	if($new_symbol eq 'na'){
		$new_symbol = $between_gene;
	}
	elsif($biotype_ref->{$new_symbol} ne "protein_coding"){
		$new_pas_type = "ncRNA";
	}
	return ($count,$new_pas_type,$new_symbol,$extend_length,$between_gene);
}

