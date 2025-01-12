from PolyAModel import *
import re
import os, sys, copy, getopt, re, argparse
import random
import pandas as pd 
import numpy as np
from Bio.Seq import Seq
import sys
from TrimmedMean import TrimmedMean
from extract_coverage_from_scanGenome import check


def collpase(pas_id,array,rst=0):
	#complement = {'A':'T','T':'A','C':'G','G':'C'}
	
	sequence = ''
	#sequence = []
	#coverage = np.zeros(len(array))
	coverage = []
	contain_N = False
	#for i,line in enumerate(array):
	for line in array:
		line = line.rstrip('\n')
		_,rpm,base = line.split('\t')
		base = base.upper()
		if(base=='N'):
			contain_N = True
			break
		sequence += base
		#sequence.append(base)
		coverage.append(rpm)
		#coverage[i] = rpm
	
	if(not contain_N):
		chromosome,pos,strand = pas_id.split(':')
		if(strand == "-"):
			sequence = Seq(sequence)
			sequence = sequence.reverse_complement()
			#sequence = [complement[base] for base in sequence]
			#sequence.reverse()

			#coverage.reverse()
			coverage = coverage[::-1]
		trimMean = TrimmedMean([float(coverage[i]) for i in range(int(len(coverage)/2))])
		if(trimMean>=rst):
			return sequence,coverage
		else:
			return 0,0
	else:
		print("Discard item containig N")
		return 0,0
	


def dataProcessing(scan_file,window,rst):
	
	extend  = int(window/2)
	alphabet = np.array(['A', 'T', 'C', 'G'])
	
	f = open(scan_file,'r')
	lines = f.readlines()
	data1 = []
	data2 = []
	PASID = []
	##data1 = np.zeros([len(lines),window,4])
	#data2 = np.zeros([len(lines),window,1])
	#PASID = np.empty(len(lines),dtype='object')
	#index = np.zeros(len(lines),dtype=bool)
	
	#n_pos = 0 #position containing N
	for i,line in enumerate(lines):
	#for line in f.readlines():
		line = line.rstrip('\n')
		pas_id,_,base = line.split('\t')
		
		if(base=='N'):
			continue
		start = i-extend
		end   = i+extend
		if(start>0 and end+1<len(lines)):
			if(not check(lines[start],lines[end],window)):
				continue
			sequence,coverage = collpase(pas_id,lines[start:end+1],rst)
			if(sequence!=0):
				chromosome,pos,strand = pas_id.split(':')
				sequence = list(sequence)
				seq = np.array(sequence, dtype = '|U1').reshape(-1,1)
				seq_data = (seq == alphabet).astype(np.float32)
				coverage = np.array(coverage).astype(np.float32)
				data1.append(seq_data)
				data2.append(coverage)
				PASID.append(pas_id)
				#data1[i,:,:] = seq_data
				#data2[i,:,:] =  coverage.reshape([-1,1])
				#PASID[i] = pas_id
				#index[i] = True

	data1 = np.stack(data1).reshape([-1, window, 4])
	data2 = np.stack(data2).reshape([-1, window, 1])
	PASID = np.array(PASID)
	#data1 = data1[index] 
	#data2 = data2[index]
	#PASID = PASID[index]
	
	f.close()
	return data1 , data2,  PASID 

def args():
	parser = argparse.ArgumentParser(description="identification of pAs cleavage site")
	parser.add_argument("--model", help="the model weights file", required=True)
	parser.add_argument('--baseName', help='baseName')
	parser.add_argument("--out_dir", help="prediction files", required=True)
	parser.add_argument("--RNASeqRCThreshold",default=0.05,type=float,help="RNA-Seq Coverage Threshold")
	parser.add_argument('--window', default=201, type=int, help='input length')
	parser.add_argument('--keep_temp',default=None,help='if you want to keep temporary file, set to "yes"')
	args = parser.parse_args()

	model = args.model
	out_dir  = args.out_dir
	rst = args.RNASeqRCThreshold
	window=args.window
	baseName = args.baseName
	#baseName = '%s.%s'%(name,baseName)
	keep_temp =  args.keep_temp
	return model,out_dir,rst,window,baseName,keep_temp

def Evaluate(model,out_dir,rst,window,baseName,keep_temp):
	if(out_dir[-1] == '/'):
		out_dir = out_dir[0:-1]
	data="%s/data/%s"%(out_dir,baseName)
	out_dir = out_dir+'/predict'
	if not os.path.exists(out_dir):
		os.makedirs(out_dir) 
	out="%s/%s.txt"%(out_dir,baseName)

	print("Start processing data")
	seq_data,cov_data,pas_id = dataProcessing(data,window,rst)
	print("Finish processing data")
	print("Start Evaluating %s"%data)

	keras_Model = PolyA_CNN(window)
	keras_Model.load_weights(model)
	pred = keras_Model.predict({"seq_input": seq_data, "cov_input": cov_data})

	OUT=open(out,'w')
	for i in range(len(pas_id)):
		OUT.write('%s\t%s\n'%(str(pas_id[i]),str(pred[i][0])))
	OUT.close()
	print("End Evaluation\n")

	if (keep_temp != "yes"):
		os.system('rm %s'%data)


			
if __name__ == "__main__":
	Evaluate(*args())

