from PolyAModel import *
import re
import os, sys, copy, getopt, re, argparse
import random
import pandas as pd 
import numpy as np
from prep_data import min_max_norm
import sys
sys.path.insert(0, '/home/longy/project/python_lib')
from TrimmedMean import TrimmedMean


def Normalization(COVERAGE,data_mean,data_std):
	#COVERAGE = (np.log(COVERAGE+1)-data_mean)/data_std
	#COVERAGE = COVERAGE*300
	return COVERAGE

def getScaler(Path):
	scaler = Path.split("/")[1]
	scaler = scaler.split('-')[0]
	scaler = 'scaler/'+scaler
	f = open(scaler,'r')
	line = f.read()
	data_mean,data_std = line.rstrip('\n').split('\t')
	data_mean = float(data_mean)
	data_std  = float(data_std)
	return data_mean,data_std

def dataProcessing(data_path,RNASeqRCThreshold,polyA_file,length,data_mean,data_std):
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
				trimMean = TrimmedMean(COVERAGE[0:int(length/2)])
				chromosome=line[2]
				position=int(line[3])
				strand=line[4]
				polyACount = [0.0 for i in range(len(COVERAGE))]
				if trimMean > RNASeqRCThreshold:
					data1.append(seq_data)
					#####scale to 0-1
					#COVERAGE = min_max_norm(COVERAGE)
					#####Log transform and standardize normalization
					COVERAGE = np.array(COVERAGE).astype(np.float32)
					COVERAGE  = Normalization(COVERAGE,data_mean,data_std)
					data2.append(COVERAGE)
					data3.append(polyACount)
					PASID.append(line[0])
	
	data1 = np.stack(data1).reshape([-1, length, 4])
	data2 = np.stack(data2).reshape([-1, length, 1])
	data3 = np.stack(data3).reshape([-1, length, 1])
	PASID = np.array(PASID)
	
	return data1 , data2, data3, PASID

if __name__ == "__main__":
	parser = argparse.ArgumentParser(description="identification of pAs cleavage site")
	parser.add_argument("--model", help="the model weights file", required=True)
	parser.add_argument("--data", help="input  sequence and coverage", required=True)
	parser.add_argument("--out", help="prediction files", required=True)
	parser.add_argument("--cov",type=float,help="RNA-Seq Coverage Threshold", required=True)
	parser.add_argument('--polyAfile', help='polyA file from RAN-Seq conataining position and polyA read counts')
	parser.add_argument('--combination', default='SC',type=str, help='Seperate the data into how many folds')
	parser.add_argument('--window', default=201, type=int, help='input length')
	args = parser.parse_args()

	Path = args.model
	data = args.data
	out  = args.out
	polyA_file = args.polyAfile
	combination = args.combination
	RNASeqRCThreshold = args.cov
	length=args.window

	data_mean=0
	data_std=1
	data_mean,data_std = getScaler(Path)
	seq_data,cov_data,polyA_data,pas_id= dataProcessing(data,RNASeqRCThreshold,polyA_file,length,data_mean,data_std)

	keras_Model = PolyA_CNN(combination,length,6,12)
	keras_Model.load_weights(Path)
	pred = keras_Model.predict({"seq_input": seq_data, "cov_input": cov_data,"pol_input": polyA_data})
	#	sys.exit("Invalid combination parameter. Plese try again with combination in [SCP SC SP CP S C P]")

	OUT=open(out,'w')
	for i in range(len(pas_id)):
		OUT.write('%s\t%s\n'%(str(pas_id[i]),str(pred[i][0])))
