#!/usr/bin/perl -w
#

my $hepg2_file = "all.hepg2_control.usage.txt";
my $thle2_file = "all.thle2_control.usage.txt";
my $snu398_file = "all.snu398_control.usage.txt";
my $k562_file = "all.k562_chen.usage.txt";


open OUT,">stat.polyArpm.txt";
print OUT "RPM\tprecision\ttrue\ttotal\tcell_line\n";
open OUT2,">stat.dist.txt";
print OUT2 "dist\tprecision\ttrue\ttotal\tcell_line\n";
&statistics($snu398_file,'snu398',0.78);
&statistics($k562_file,'k562',3.33);
&statistics($thle2_file,'thle2',0.89);
&statistics($hepg2_file,'hepg2',0.62);


sub statistics{
	my ($file,$cell,$times) = @_;
	open FILE,"$file";
	<FILE>;
	my %polyA_correct;
	my %dist_correct;
	my $total = 0;
	while(<FILE>){
		chomp;
		my ($pas_id,$is_ground_true,$nearest_pas,$symbol,$pas_type,undef,undef,$usage,$polyA_readcount) = split;
		$total++;
		my $predict_pos = (split /\:/,$pas_id)[1];
		my $true_pos    = (split /\:/,$nearest_pas)[1];
		my $diff = abs($predict_pos-$true_pos);
		for (my $i=100;$i>=5;$i-=5){
			if($diff <=$i){
				$dist_correct{$i}++;
			}
			else{
				last;
			}

		}
		for (my $i=1;$i<=10;$i++){
			if($polyA_readcount>=$i/2*$times){
				$polyA_correct{$i}++;
			}
			else{
				last;
			}
		}
	}
	for (my $i=1;$i<=10;$i++){
		my $true_number = $polyA_correct{$i};
		my $percent = $true_number/$total;
		my $rpm = $i/10;
		print OUT "$rpm\t$percent\t$true_number\t$total\t$cell\n";
		my $dist = $i*5;
		my $dist_true_number = $dist_correct{$dist};
		my $dist_percent = $dist_true_number/$total;
		print OUT2 "$dist\t$dist_percent\t$dist_true_number\t$total\t$cell\n";
	}
}
