#!/usr/bin/perl -w

my ($ENS,$Inp,$Out) = @ARGV;

my %all_ens_gene;
open ENS,"zcat $ENS | awk '(\$3 ==\"gene\")' | ";
while(<ENS>){
	next if $_ =~ /^\#/;
	my ($gene_name,$gene_type) = (split)[13,17];
	$gene_name =~ s/\"|\;//g;
	$all_ens_gene{$gene_name} = '';
}



open FILE,"$Inp";
<FILE>;
open OUT,">$Out";
print OUT "pas_id\tpas_type\tchr\tposition\tstrand\tsymbol\tusage\t3'Seq_readCount\tmotif\tave_diff\tUpstream_readCouunt\tbiotype\textend\told_symbol\tsymbol_remark\n";

my @data = <FILE>;

#foreach (@data){
my %pre_symbol = ('+'=>'','-'=>'');
for($i=0;$i<@data;$i++){
	chomp $data[$i];
	my ($pas_id,$pas_type,$chr,$pos,$srd,$symbol,$usage,$readCount,$motif,$ave_diff,$upstream_rc,$new_symbol,$new_pas_type,$extension,$between_gene,$biotype) = (split /\t/ , $data[$i]);
	if($new_pas_type eq "Overlap"){
		$j = 1;
		my ($nex_srd,$nex_symbol,$nex_pas_type,$nex_bg,$nex_bt) = (split /\t/,$data[$i+$j])[4,11,12,14,15];
		while($nex_pas_type eq "Overlap" || $nex_srd eq $srd){
			$j++;
			($nex_srd,$nex_symbol,$nex_pas_type,$nex_bg,$nex_bt) = (split /\t/,$data[$i+$j])[4,11,12,14,15];
		}
		if($pre_symbol{$srd} eq $nex_symbol){
			$new_symbol = $nex_symbol;
			$extension   = "No";
			$new_pas_type = $nex_pas_type;
			$between_gene = $nex_bg;
			$biotype = $nex_bt;
		}
	}
	
	my $symbol_remark = "Same";
	if($symbol ne $new_symbol){
		if($symbol eq "na"){
			$symbol_remark = "New_gene";
		}
		elsif(!exists $all_ens_gene{$symbol}){
			$symbol_remark = "Update";
		}
		else{
			$symbol_remark = "Different";
		}
	}

	$pre_symbol{$srd} = $new_symbol;
	$new_symbol = $between_gene if $new_symbol eq "na";
	print OUT "$pas_id\t$new_pas_type\t$chr\t$pos\t$srd\t$new_symbol\t$usage\t$readCount\t$motif\t$ave_diff\t$upstream_rc\t$biotype\t$extension\t$symbol\t$symbol_remark\n";
}
