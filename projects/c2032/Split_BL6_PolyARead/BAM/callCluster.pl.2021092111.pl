#!/usr/bin/perl -w
use strict;
use Math::CDF;

=use
call the 3p-seq cluster ...
...
=cut

my $CLUSTER_SIZE=24;

sub abs {
	my ($n1,$n2) = @_;
	my $v = 0;
	if($n1 < $n2){
		$v = $n2 - $n1;
	}elsif($n1 > $n2){
		$v = $n1 - $n2;
	}
	return($v);
}

### call cluster based on tianbin's paper ...
sub callCluster {
	my ($bed,$clusterout,$distanceout,$ifstrand) = @_;
	open IN,"$bed" or die $!;
	my %Locus;
	my %NonStrLocus;
	while(<IN>){
		chomp;
		my @Columns = split;
		my $end = 0;
		### sequenced antisense 
		if($ifstrand == 2){
			$end = $Columns[2] if($Columns[5] =~ /\-/);
			$end = $Columns[1] if($Columns[5] =~ /\+/);
		### squenced sense 
		}elsif($ifstrand == 1){
			$end = $Columns[1] if($Columns[5] =~ /\-/);
			$end = $Columns[2] if($Columns[5] =~ /\+/);
		}elsif($ifstrand == 0){
			if(!(exists $NonStrLocus{$Columns[0]}{$Columns[1]})){
				$NonStrLocus{$Columns[0]}{$Columns[1]} = 1;
			}else{
				my $c = $NonStrLocus{$Columns[0]}{$Columns[1]};
				$c ++;
				$NonStrLocus{$Columns[0]}{$Columns[1]} = $c;
			}
			if(!(exists $NonStrLocus{$Columns[0]}{$Columns[2]})){
				$NonStrLocus{$Columns[0]}{$Columns[2]} = 1;
			}else{
				my $c = $NonStrLocus{$Columns[0]}{$Columns[2]};
				$c ++;
				$NonStrLocus{$Columns[0]}{$Columns[2]} = $c;
			}
		}else{
			print "error: undefined value for stranded information\n";
		}
		### count reads at each genomic locus 
		if(!(exists $Locus{$Columns[0]}{$Columns[5]}{$end})){
			$Locus{$Columns[0]}{$Columns[5]}{$end} = 1;
		}else{
			my $c = $Locus{$Columns[0]}{$Columns[5]}{$end};
			$c ++;
			$Locus{$Columns[0]}{$Columns[5]}{$end} = $c;
		}
	}
	close IN;
	my %SelectedLocus;
	my %StrandCount;
	if($ifstrand == 0){
		print "...redefine the strand information due to sequencing data is strandless...\n";
		open IN,"$bed" or die $!;
		while(<IN>){
			chomp;
			my @Columns = split;
			my $end = $Columns[1];
			$end = $Columns[2] if($NonStrLocus{$Columns[0]}{$Columns[2]} > $NonStrLocus{$Columns[0]}{$Columns[1]});
			if(!(exists $SelectedLocus{$Columns[0]}{$end})){
				$SelectedLocus{$Columns[0]}{$end} = 1;
			}else{
				my $c = $SelectedLocus{$Columns[0]}{$end};
				$c ++;
				$SelectedLocus{$Columns[0]}{$end} = $c;
			}
			if(!(exists $StrandCount{$Columns[0]}{$end}{$Columns[5]})){
				$StrandCount{$Columns[0]}{$end}{$Columns[5]} = 1;
			}else{
				my $c = $StrandCount{$Columns[0]}{$end}{$Columns[5]};
				$c ++;
				$StrandCount{$Columns[0]}{$end}{$Columns[5]} = $c;
			}
		}
		close IN;
		foreach my $chr(keys %SelectedLocus){
			foreach my $l (keys %{$SelectedLocus{$chr}}){
				my $n = 0;
				my $str = "";
				foreach my $s (keys %{$StrandCount{$chr}{$l}}){
					$str = $s if($StrandCount{$chr}{$l}{$s} > $n);
					$n = $StrandCount{$chr}{$l}{$s};
				}
				$Locus{$chr}{$str}{$l} = $SelectedLocus{$chr}{$l};
			}
		}
	}
#=test
	#my @Distance;
	my $tc = 0;
	my $tc1 = 0;
	my %Cluster;
	my %Singles;
	open OUT,">$distanceout" or die $!;
	foreach my $chr(keys %Locus){
		foreach my $strand (keys %{$Locus{$chr}}){
			my $tmp = 0;
			my $start = 0;
			### use the mark to indicate if the before one loci is far than 24 ...  
			my $mark = 1;
			my $last = 0;
			###
			foreach my $end (sort {$a<=>$b} keys %{$Locus{$chr}{$strand}}){
				#print "$chr\t$strand\t$tmp\t$end\n";
				$last = $end;
				my $num = $Locus{$chr}{$strand}{$end};
				$tc = $tc + $num;
				if($tmp == 0){
					$tmp = $end;
				}else{
					my $d = $end - $tmp;
					#push @Distance,$d;
					print OUT "$chr\t$tmp\t$end\t$chr|$strand|NA|NA|NA\t$d\t$strand\n";
					if($d < $CLUSTER_SIZE + 1){
						#$tn ++;
						if($start == 0){
							$start = $tmp;
						}
						push @{$Cluster{$chr}{$strand}{$start}},$end;
						$mark = 0;
					}else{
						$start = 0;
						if($mark == 0){
							$mark = 1;
						}else{
							if(exists $Locus{$chr}{$strand}{$tmp}){
								$Singles{$chr}{$strand}{$tmp} = $Locus{$chr}{$strand}{$tmp};
								$tc1 = $tc1 + $Locus{$chr}{$strand}{$tmp};
							}else{
								print "the $tmp is not included in the hash\n";
							}
						}
						#delete($Locus{$chr}{$strand}{$end});
					}
					$tmp = $end;
				}
			}
			#print "the chr is $chr and strand is $strand the last is $last and the start is $start and the and the tmp is $tmp\n";
			if($start == 0){
				$Singles{$chr}{$strand}{$last} = $Locus{$chr}{$strand}{$last};
				$tc1 = $tc1 + $Locus{$chr}{$strand}{$last};
			}
		}
	}
	print "there are totally $tc reads in all loci\n";
	print "there are totally $tc1 reads in single loci\n";
	close OUT;
	open OUT,">$clusterout" or die $!;
	my $tc2 = 0;
	foreach my $chr(keys %Cluster){
		foreach my $strand(keys %{$Cluster{$chr}}){
			foreach my $start(keys %{$Cluster{$chr}{$strand}}){
				$tc2 = $tc2 + $Locus{$chr}{$strand}{$start};
				my @Al = @{$Cluster{$chr}{$strand}{$start}};
				if(exists $Singles{$chr}{$strand}{$start}){
					print "duplicted counting: $start\n";
				}
				foreach my $a(@Al){
					if($a == $start){
						print "location $a is duplicated\n";
					}
					$tc2 = $tc2 + $Locus{$chr}{$strand}{$a};
					if(exists $Singles{$chr}{$strand}{$a}){
						print "duplicted counting: $start\n";
					}
				}
				#### the cluster size <= 24 
				if($Al[$#Al] - $start < $CLUSTER_SIZE + 1){
					### initialize the peak and reads number the first position .... 
					my $peak = $start;
					my $num = 0;
					if(exists $Locus{$chr}{$strand}{$peak}){
						$num = $Locus{$chr}{$strand}{$peak};
					}else{
						print "location $peak doesn't exist in hash\n";
					}
					###  ... find the peak and sum the reads number 
					for(0..$#Al){
						my $l = $Al[$_];
						if(exists $Locus{$chr}{$strand}{$l}){
							$num = $num + $Locus{$chr}{$strand}{$l};
							if($Locus{$chr}{$strand}{$l} > $Locus{$chr}{$strand}{$peak}){
								$peak = $l;
							}
						}else{
							print "location $l doesn't exist in hash\n";
						}
					}	
					my $id = $chr."|".$strand."|NA|".$peak."|".$num;
					if($strand eq "-"){
						my $p = $peak - 1;
						my $ss = $start - 1;
						print OUT "$chr\t$ss\t$Al[$#Al]\t$id\t$num\t$strand\t$p\t$peak\n";
					}elsif($strand eq "+"){
						my $p = $peak + 1;
						my $ss = $Al[$#Al] + 1;
						print OUT "$chr\t$start\t$ss\t$id\t$num\t$strand\t$peak\t$p\n";
					}else{
						print "error:strand $strand information is wrong\n";
					}
				}else{
					### the cluster size larger than 24 ... 
					#print "bigcluster....$chr\t$start\t$Al[$#Al]\t$#Al\n";
					if($#Al > 0){
						my @Nal = @Al;
						my @Ad;
						push @Ad,$start;
						unshift @Nal,@Ad;
						### loop ... exit when only one elemnt in the array ...
						while($#Nal > 0){
							### initilize the peak ...
							my $npeak = $Nal[0];
							#print "peak is $npeak\n";
							for(1..$#Nal){
								my $l = $Nal[$_];
								if(exists $Locus{$chr}{$strand}{$l}){
									#$num = $num + $Locus{$chr}{$strand}{$l};
									if($Locus{$chr}{$strand}{$l} > $Locus{$chr}{$strand}{$npeak}){
										$npeak = $l;
									}
								}else{
									print "location $l doesn't exist in hash\n";
								}
							}
							my $left = $npeak;
							my $right = $npeak;
							my $k = 0;
							my @ReAl = @Nal;
							my $nnum = 0;
							for(0..$#Nal){
								my $l = $Nal[$_];
								my $d = 0;
								if($l < $npeak){
									$d = $npeak - $l;
								}else{
									$d = $l - $npeak;
								}
								#print "the dis is $d\n";
								if($d < $CLUSTER_SIZE + 1){
									#print "the d is $d and the l is $l and the peak is $npeak\n";
									if($l < $left){
										$left = $l;
									}
									if($l > $right){
										$right = $l;
									}
									$nnum = $nnum + $Locus{$chr}{$strand}{$l};
									#print "array is @ReAl\n";
									splice(@ReAl,$_ - $k,1);
									$k ++;
									#print "left array is @ReAl\n";
								}
							}
							if($left == $right){
								$Singles{$chr}{$strand}{$left} = $Locus{$chr}{$strand}{$right};
							}else{
								my $id = $chr."|".$strand."|NA|".$npeak."|".$nnum;
								if($strand eq "-"){
									my $p = $npeak - 1;
									my $ll = $left - 1;
									print OUT "$chr\t$ll\t$right\t$id\t$nnum\t$strand\t$p\t$npeak\n";
								}elsif($strand eq "+"){
									my $p = $npeak + 1;
									my $ll = $right + 1;
									print OUT "$chr\t$left\t$ll\t$id\t$nnum\t$strand\t$npeak\t$p\n";
								}else{
									print "error: wrong strand information: $strand\n";
								}
							}
							@Nal = @ReAl;
							#print "left array is @Nal\n";
						}
						if($#Nal == 0){
							my $num = 0;
							if(exists $Locus{$chr}{$strand}{$Nal[0]}){
								$num = $Locus{$chr}{$strand}{$Nal[0]};
							}else{
								print "$Nal[0] doesn't exist in hash\n";
							}
							$Singles{$chr}{$strand}{$Nal[0]} = $num;
						}
					}else{
						print "error:$Al[0]\t$start\n";
					}
				}
			}
		}
	}
	print "there are totally $tc2 reads in the cluster\n";
	foreach my $chr(keys %Singles){
		foreach my $strand(keys %{$Singles{$chr}}){
			foreach my $l(keys %{$Singles{$chr}{$strand}}){
				#if(($l == 195149871) or ($l == 195345401)){
				#	print "the locus is in the singles\n";
				#}
				my $num = $Singles{$chr}{$strand}{$l};
				$tc2 = $tc2 + $num;
				my $id = $chr."|".$strand."|NA|".$l."|".$num;
				if($strand eq "-"){
					my $ll = $l - 1;
					print OUT "$chr\t$ll\t$l\t$id\t$num\t$strand\t$ll\t$l\n";
				}elsif($strand eq "+"){
					my $ll = $l + 1;
					print OUT "$chr\t$l\t$ll\t$id\t$num\t$strand\t$l\t$ll\n";
				}else{
					print "error:strand $strand information is not recoglized\n";
				}
			}
		}
	}
	close OUT;
#=cut
}

my $ifstrand = 1;
#=test
if(@ARGV < 3){
	print "usage:bed\tclusterout\tditanceout\n";
	exit(0);
}else{
	$ifstrand = $ARGV[3] if(defined $ARGV[3]);
#	print "stranded is $ifstrand\n";
	if($ifstrand != 1 and $ifstrand != 2 and $ifstrand != 0){
		print "error: stranded information $ifstrand is not correct\n";
		exit(0);
	}
	&callCluster($ARGV[0],$ARGV[1],$ARGV[2],$ifstrand);
}
#=cut

