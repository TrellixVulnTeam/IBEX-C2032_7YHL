#!/usr/bin/perl -w
#


#open FILE,"../predict/BL6_REP1.pAs.single_kermax6.BL6_REP1_aug8_SC_p5r10u0.05_0-0073.chr10_-_1.txt";
#my $start = 24637926-200;
#my $end   = 24641414+200;
#open FILE,"../predict/BL6_REP1.pAs.single_kermax6.BL6_REP1_aug8_SC_p5r10u0.05_0-0073.chr10_+_0.txt";
#my $start = 24188288-200;
#my $end   = 24188946+200;

#open FILE,"../predict/BL6_REP1.pAs.single_kermax6.BL6_REP1_aug8_SC_p5r10u0.05_0-0073.chr1_-_0.txt";
#my $start = 10024599-200;
#my $end   = 10024817+200;
open FILE,"../predict/K562_Chen.pAs.single_kermax6.K562_Chen_aug12_SC_p4r0.05u0.05_4-0254.chr1_-_1.txt";
my $start = 29147834-50;
my $end   = 29147882+50;

open OUT,">score.txt";
print OUT "position\tscore\n";
my $middle  = ($start+$end)/2;

my %hash;
for(my$i=$start+1;$i<$end;$i++){
	$hash{$i-$middle} = 0;
}

while(<FILE>){
	chomp;
	my ($pas_id,$score) = split;
	my ($chr,$pos,$strand) = split /\:/,$pas_id;
	if($start<$pos && $end > $pos){
		my $relative_pos = $pos-$middle;
		$hash{-$relative_pos} = $score;
	}
}

foreach my $key(sort{$b<=>$a} keys %hash){
	print OUT "$key\t$hash{$key}\n";
}
