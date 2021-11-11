package Upstream;
require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT = qw/Determine_intronic Determine_antisense/;

sub Determine_intronic{
	my ($exon_loc,$pos) = @_;
	my $pas_type = 'UR';
	my $trans_count = 0;
	my $trans_stat = 0;
	while (my ($trans_id,$pos_vals) = each %$exon_loc){
		foreach my $pos_val (keys %$pos_vals){
			my ($start,$end) = split /,/,$pos_val;
			if($pos>=$start && $pos <= $end){
				$trans_stat++;
			}
		}
		$trans_count++;
	}
	if($trans_stat == $trans_count){
		$pas_type = "Exonic";
	}
	elsif($trans_stat < $trans_count){
		$pas_type = "Intronic"
	}
	else{
		print "Invalid\n";
	}
	return $pas_type;
}

sub Determine_antisense{
	my ($tss_loc,$Antisense_extend,$sign,$pos,$new_symbol) = @_;
	my $pas_type = 'intergenic';
	my $gene_name = '';
	my $min_diff = $Antisense_extend + 2;
	while(my ($start,$symbol) = each %$tss_loc){
		my $diff = ($pos-$start)*$sign;
		if($diff>0 && $diff<$min_diff){
			$min_diff = $diff;
			$gene_name = $symbol;
		}
	}
	if($min_diff < $Antisense_extend){
		$pas_type = "upstream_antisense";
		$new_symbol = "$gene_name-UA";
	}
	return $pas_type,$new_symbol;
}
