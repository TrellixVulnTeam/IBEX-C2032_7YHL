#!/bin/bash

#python src/DaPars_Extract_Anno.py  -b DaPars2_Test_Dataset/hg19_refseq_whole_gene.bed -s DaPars2_Test_Dataset/Refseq_id_from_UCSC.txt -o hg19_refseq_extracted_3UTR.bed

#python src/Dapars2_Multi_Sample.py DaPars2_test_data_configure.txt chr3


python src/DaPars_Extract_Anno.py  -b DaPars2_Test_Dataset/hg19_refseq_whole_gene.bed -s DaPars2_Test_Dataset/Refseq_id_from_UCSC.txt -o hg19_refseq_extracted_3UTR.bed
