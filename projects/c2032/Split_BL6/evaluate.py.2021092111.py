from PolyAModel import *
import re
import os, sys, copy, getopt, re, argparse
import random
import pandas as pd 
import numpy as np
from prep_data import min_max_norm



def trimmedMean(UpCoverage):
	total = 0
	count=0
	for cov in UpCoverage:
		if(cov>0):
			total += cov
			count += 1
	trimMean = 0
	if count >20:
		trimMean = total/count;
	return trimMean

def dataProcessing(data_path,RNASeqRCThreshold,polyA_file,length):
	data1 = []
	data2 = []
	data3 = []
	PASID = []
	alphabet = np.array(['A', 'T', 'C', 'G'])
	polyA_dict = dict()
	with open(polyA_file,'r') as f:
		for line in f:
			line=line.rstrip('\n').split('\t')
			polyA_dict[line[0]] = line[1]


	with open(data_path,'r') as f:
		for line in f:
			line=line.rstrip('\n').split('\t')
			if (line[0]!='#pas_id')&(line[0]!='pas_id'):
				SEQUENCE=list(line[7])
				SEQUENCE=SEQUENCE[0:length]
				seq = np.array(SEQUENCE, dtype = '|U1').reshape(-1,1);
				seq_data = (seq == alphabet).astype(np.float32)
				COVERAGE=[float(x) for x in line[8:length+8]]
				trimMean = trimmedMean(COVERAGE[50:150])
				chromosome=line[2]
				position=int(line[3])
				strand=line[4]
				polyACount = [0.0 for i in range(len(COVERAGE))]
				"""
				for i in range(len(COVERAGE)):
					if (strand == "+"):
						pos = position-100+i
					else:
						pos = position+100-i
					pasid = chromosome+':'+str(pos)+':'+strand
					if pasid in polyA_dict.keys():
						polyACount[i] = float(polyA_dict[pasid])
				"""
				trimMean = 100
				if trimMean > RNASeqRCThreshold:
					data1.append(seq_data)
					#####scale to 0-1
					#COVERAGE = min_max_norm(COVERAGE)
					data2.append(COVERAGE)
					data3.append(polyACount)
					PASID.append(line[0])
	
	data1 = np.stack(data1).reshape([-1, length, 4])
	data2 = np.stack(data2).reshape([-1, length, 1])
	data3 = np.stack(data3).reshape([-1, length, 1])
	PASID = np.array(PASID)
	
	return data1 , data2, data3, PASID

def main():
	parser = argparse.ArgumentParser(description="identification of pAs cleavage site")
	parser.add_argument("--model", help="the model weights file", required=True)
	parser.add_argument("--data", help="input  sequence and coverage", required=True)
	parser.add_argument("--out", help="prediction files", required=True)
	parser.add_argument("--cov",type=int,help="RNA-Seq Coverage Threshold", required=True)
	parser.add_argument('--polyAfile', help='polyA file from RAN-Seq conataining position and polyA read counts')
	parser.add_argument('--combination', default='SC',type=str, help='Seperate the data into how many folds')
	args = parser.parse_args()

	Path = args.model
	data = args.data
	out  = args.out
	polyA_file = args.polyAfile
	combination = args.combination
	RNASeqRCThreshold = args.cov
	#length=176
	length=301
	OUT=open(out,'w')
	seq_data,cov_data,polyA_data,pas_id= dataProcessing(data,RNASeqRCThreshold,polyA_file,length)
	keras_Model = PolyA_CNN(combination,length);
	keras_Model.load_weights(Path)
	pred = keras_Model.predict({"seq_input": seq_data, "cov_input": cov_data,"pol_input": polyA_data})
	#§	sys.exit("Invalid combination parameter. Plese try again with combination in [SCP SC SP CP S C P]")

	for i in range(len(pas_id)):
		OUT.write('%s\t%s\n'%(str(pas_id[i]),str(pred[i][0])))
	
if __name__ == "__main__":
	main()
