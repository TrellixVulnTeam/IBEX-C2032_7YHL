package Augmentation;
require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT = qw/Augmentation/;
use TrimmedMean;

sub Augmentation{
	my ($i,$pos,$pas_id,$pas_type,$symbol,$RNASeqRCThreshold,$Shift,$lines_ref) = @_;
	my @meta_data;
	for (my $j=$i-$Shift;$j<=$i+$Shift;$j++){
		chomp $lines_ref->[$j];
		my @shift_data = split /\t/,$lines_ref->[$j];
		my $SRD = $shift_data[2];
		my $shift_pos = $shift_data[3];
		my $shift_diff = $pos-$shift_pos;
		if (abs($shift_diff) <= $Shift){
			$shift_data[6] = $pas_id;
			if($shift_diff<0){
				if ($SRD eq "+"){
					$shift_data[5] = "Up".abs($shift_diff);
				}
				else{
					$shift_data[5] = "Dn".abs($shift_diff);
				}
			}
			elsif($shift_diff>0){
				if ($SRD eq "+"){
					$shift_data[5] = "Dn".abs($shift_diff);
				}
				else{
					$shift_data[5] = "Up".abs($shift_diff);
				}
			}
			else{
				$shift_data[5] = 'Origin';
			}
			my $length = int((@shift_data-8)/2);
			my $before = &TrimmedMean(@shift_data[8..8+$length]);
			next if $before <= $RNASeqRCThreshold;
			$shift_data[1] = "$shift_data[1]\_$pas_type\_$symbol";
			#return @shift_data;
			push (@meta_data,\@shift_data);
		}
	}
	return @meta_data;
}
