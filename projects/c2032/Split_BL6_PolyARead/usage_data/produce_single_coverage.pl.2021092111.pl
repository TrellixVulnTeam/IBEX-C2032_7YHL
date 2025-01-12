#!/usr/bin/perl -w
#
my $WIG = "/home/longy/project/Split_BL6/STAR/BL6_REP1/Signal.Unique.str1.out.chr6.wig";
my $SRD  = "-";
open OUT,">Coverage.Zfp800";
my $pos1 = 28239931;
my $pos2 = 28242234;
my $extend = 1000;

open FILE,$WIG;
my %cov;
<FILE>;
while(<FILE>){
	chomp;
	my ($pos,$read) = split;
	if($pos>$pos1-$extend){
		$cov{$pos} = $read;
	}
	last if $pos > $pos2+$extend;
}

my $window = $pos2-$pos1+2*$extend;;
my @array = (0)x($window);
for(my $i=0;$i<$window;$i++){
	my $each_pos = $pos1-$extend+$i;
	if(exists $cov{$each_pos}){
		$array[$i] = $cov{$each_pos};
	}
}
@array = reverse @array if $SRD eq "-";
print OUT join ("\t",@array),"\n";
