#!/usr/bin/env python3

import numpy as np
import os
import sys
import argparse
import glob
from sklearn.model_selection import KFold
from collections import defaultdict
from tensorflow.keras.utils import Sequence

def min_max_norm(x):
	min_val = np.min(x)
	max_val = np.max(x)
	x = (x-min_val) / (max_val-min_val)
	return x


def get_files(root_dir,block_dir,RoundName,label):
	Round = int(RoundName[-1])
	Fold=5
	blockfiles = glob.glob(block_dir+"/chr*")
	blockfiles = np.array(sorted(blockfiles))
	if(label=='positive'):
		root_dir = root_dir+'/positive/'+RoundName[0:-2]
	else:
		root_dir = root_dir+'/negative/'+RoundName
	files = []
	for f in blockfiles:
		f2 = f.replace(block_dir,root_dir)
		files.append(f2)
	files = np.array(files)
	np.random.seed(0)
	####Chose 18 blocks as Test Set
	test_index = np.random.choice(range(len(files)),2,replace=False)
	####The remaining sets as train and valid sets
	new_files = np.delete(files,test_index)
	#### 5 Fold cross validation
	kf = KFold(n_splits = Fold,random_state=0,shuffle=True)
	train_round = []
	valid_round = []
	for train,valid in kf.split(new_files):
		train_round.append(train)
		valid_round.append(valid)

	train_sets = new_files[train_round[Round%Fold]]
	valid_sets = new_files[valid_round[Round%Fold]]
	test_sets  = files[test_index]

	return train_sets,valid_sets,test_sets


def get_data(root_dir,block_dir,polyA_file,RoundName,label,subset):
	"""
	Process all files in the input directory to read sequences.
	Sequences are encoded with one-hot.
	data_root: input directory
	label: the label (True or False) for the sequences in the input directory
	"""
	data1 = dict() # seq
	data2 = dict() # coverage
	data3 = dict() # polyA containing reads 
	labels= dict() # labels
	meta_data = defaultdict(list)
	
	train_sets,valid_sets,_ = get_files(root_dir,block_dir,RoundName,label)


	sets = None
	if subset == 'train':
		sets = train_sets
	elif subset == 'valid':
		sets = valid_sets
	else:
		sys.exit("Invalid subset. subset should be train or valid")


	polyA_dict = dict()
	with open(polyA_file,'r') as f:
		for line in f:
			line=line.rstrip('\n').split('\t')
			polyA_dict[line[0]] = line[1]

			
	for file_path in sets:
		with open(file_path,'r') as f:
			for line in f:
				line=line.rstrip('\n').split('\t')
				#validation dataset do not need data augmentation
				if line[0] !='#pas_id' and line[0] !='pas_id' and (subset == 'train' or (subset=='valid' and line[5]=='Origin')):
					pas_id = line[0]
					SEQUENCE=list(line[7])
					SEQUENCE=SEQUENCE[0:176]
					alphabet = np.array(['A', 'T', 'C', 'G'])
					seq = np.array(SEQUENCE, dtype = '|U1').reshape(-1, 1)
					seq_data = (seq == alphabet).astype(np.float32)
					#data1.append(seq_data)
					data1[pas_id] = seq_data
					#COVERAGE=[float(x) for x in line[8:184]]
					COVERAGE = np.array(line[8:184]).astype(np.float32)
					#COVERAGE = min_max_norm(COVERAGE)
					#data2.append(COVERAGE)
					data2[pas_id] = COVERAGE.reshape([-1,1])
					chromosome=line[2]
					position=int(line[3])
					strand=line[4]
					polyACount = [0.0 for i in range(len(COVERAGE))]
					for i in range(len(COVERAGE)):
						if (strand == "+"):
							pos = position-100+i
						else:
							pos = position+100-i
						pasid = chromosome+':'+str(pos)+':'+strand
						if pasid in polyA_dict.keys():
							polyACount[i] = polyA_dict[pasid]

					#data3.append(polyACount)
					data3[pas_id] = np.array(polyACount).astype(np.float32).reshape([-1,1])
					meta_data[line[6]].append(pas_id)


					if label == 'positive':
						labels[pas_id] = 1
					elif label == 'negative':
						labels[pas_id] = 0
					else:
						sys.exit("Invalid label. Label should be positive or negative")

	#data1 = np.stack(data1).reshape([-1, 176, 4])
	#data2 = np.stack(data2).reshape([-1, 176, 1])
	#data3 = np.stack(data3).reshape([-1, 176, 1])



	#if label == "positive":
	#	labels = np.ones(data1.shape[0])
	#else:
	#	labels = np.zeros(data1.shape[0])
	return data1, data2, data3, meta_data,labels


def shuffle(dataset1, dataset2, dataset3, labels, randomState=None):
	"""
	Shuffle sequences and labels jointly
	"""
	if randomState is None:
		permutation = np.random.permutation(labels.shape[0])
	else:
		permutation = randomState.permutation(labels.shape[0])
	shuffled_data1 = dataset1[permutation,:,:]
	shuffled_data2 = dataset2[permutation,:,:]
	shuffled_data3 = dataset3[permutation,:,:]
	shuffled_labels = labels[permutation]
	return shuffled_data1, shuffled_data2, shuffled_data3, shuffled_labels


def prep_data(ROOT_DIR,BLOCK_DIR,polyA_file,ROUNDNAME,NUM_FOLDS,subset,OUT=None):
	pos_data1, pos_data2, pos_data3, pos_meta_data,pos_labels = get_data(ROOT_DIR,BLOCK_DIR,polyA_file,ROUNDNAME, 'positive',subset)
	print('Size of %s positive dataset: %d'%(subset,len(pos_meta_data)))
	print('Size of %s positive augmentation dataset: %d'%(subset,len(pos_labels)))
	neg_data1, neg_data2, neg_data3, neg_meta_data,neg_labels = get_data(ROOT_DIR,BLOCK_DIR,polyA_file,ROUNDNAME, 'negative',subset)
	print('Size of %s negative dataset: %d'%(subset,len(neg_meta_data)))
	print('Size of %s negative augmentation dataset: %d'%(subset,len(neg_labels)))
	#data1 = np.concatenate((pos_data1, neg_data1), axis=0)
	#data2 = np.concatenate((pos_data2, neg_data2), axis=0)
	#data3 = np.concatenate((pos_data3, neg_data3), axis=0)
	#labels = np.concatenate((pos_labels, neg_labels), axis=0)
	data1 = {**pos_data1, **neg_data1}
	data2 = {**pos_data2, **neg_data2}
	data3 = {**pos_data3, **neg_data3}
	meta_data = {**pos_meta_data,**neg_meta_data}
	labels= {**pos_labels,**neg_labels}


	#data1,data2,data3,labels = shuffle(data1, data2 ,data3, labels)
	dataset = ({"seq_input": data1, "cov_input": data2,"pol_input": data3,"meta_data":meta_data}, labels)

	#Assert(pos_sets,neg_sets)

	#print('Size of %s dataset: %d'%(subset,len(labels)))

	if OUT is not None:
		np.savez(OUT, **dataset)
		print('Finish writing dataset to %s'%OUT)


	return dataset
	#return data1,data2,data3,meta_data,labels
	
class DataGenerator(Sequence):
	'Generates data for Keras'
	def __init__(self, datasets, labels, batch_size=32,n_classes=2, shuffle=True):
		'Initialization'
		self.batch_size = batch_size
		self.labels = labels
		self.n_classes = n_classes
		self.shuffle = shuffle
		self.datasets = datasets
		#####Original pas id. data augmentation to shift the pas  
		self.list_IDs = [*datasets['meta_data']]
		#np.random.shuffle(self.list_IDs)
		self.sizes = len(self.list_IDs)
		#self.indexes = np.arange(self.sizes)
		#np.random.shuffle(self.indexes)
		#self.list_IDs = [self.list_IDs[k] for k in self.indexes]
		self.on_epoch_end()

	def __len__(self):
		'Denotes the number of batches per epoch'
		return int(np.floor(self.sizes / self.batch_size))

	def __getitem__(self, index):
		'Generate one batch of data'
		# Generate indexes of the batch
		indexes = self.indexes[index*self.batch_size:(index+1)*self.batch_size]

		# Find list of IDs
		list_IDs_temp = [self.list_IDs[k] for k in indexes]

		# Generate data
		X, y = self.__data_generation(list_IDs_temp)

		return X, y

	def on_epoch_end(self):
		'Updates indexes after each epoch'
		self.indexes = np.arange(self.sizes)
		if self.shuffle == True:
			np.random.shuffle(self.indexes)

	def __data_generation(self, list_IDs_temp):
		'Generates data containing batch_size samples' 
		# Initialization
		
		seq_input = self.datasets['seq_input']
		cov_input = self.datasets['cov_input']
		pol_input = self.datasets['pol_input']
		meta_data = self.datasets['meta_data']
		
		seq_data = np.empty((self.batch_size, next(iter(seq_input.values())).shape[0], next(iter(seq_input.values())).shape[1]))
		cov_data = np.empty((self.batch_size, next(iter(cov_input.values())).shape[0], next(iter(cov_input.values())).shape[1]))
		pol_data = np.empty((self.batch_size, next(iter(pol_input.values())).shape[0], next(iter(pol_input.values())).shape[1]))
		cop_data = np.empty((self.batch_size, next(iter(pol_input.values())).shape[0], 2))
		y = np.empty((self.batch_size), dtype=int)
		# Generate data
		for i, ID in enumerate(list_IDs_temp):
			# Store sample
			#####Data augmentation
			PASID = np.random.choice(meta_data[ID]) ###Randomly selected one
			seq_data[i,] = seq_input[PASID] 
			cov_data[i,] = cov_input[PASID] 
			pol_data[i,] = pol_input[PASID] 
			cop_data[i,] = np.concatenate((cov_input[PASID],pol_input[PASID] ), axis=1)
			#print(seq_data[i],PASID)
			# Store class
			y[i] = self.labels[PASID]
		#X = {"seq_input": seq_data, "cov_input": cov_data,"pol_input": pol_data}
		X = {"seq_input": seq_data, "cov_input": cov_data,"pol_input": pol_data,"cop_input":cop_data}

		return X,y	
	
	
	

def Assert(pos_sets,neg_sets):
	n = len(pos_sets)
	m = len(neg_sets)
	if(m!=n):
		print("Warning! Size of positive and negative datasets is different!")

	else:
		indicator = 0
		for i in range(n):
			pos_file = pos_sets[i]
			neg_file = neg_sets[i]
			pos_baseName = pos_file.split('/')[-1]
			neg_baseName = neg_file.split('/')[-1]
			if(pos_baseName != neg_baseName):
				print('Warning! Name of positive and negative file is different')
				indicator = 1
		if(indicator==0):
			print('Positive and negative dataset is normal')

if __name__ == "__main__":
	### Argument Parser
	parser = argparse.ArgumentParser()
	parser.add_argument('--root_dir', help='Directory of files containing positive and negative files')
	parser.add_argument('--block_dir', help='Directory of files containing scan transcriptime files')
	parser.add_argument('--round',help='Round of training')
	parser.add_argument('--out', help='Save the processed dataset to')
	parser.add_argument('--polyAfile', help='polyA file from RAN-Seq conataining position and polyA read counts')
	parser.add_argument('--nfolds', default=5, type=int, help='Seperate the data into how many folds')
	opts = parser.parse_args()

	############Global Parameters ############
	NUM_FOLDS = opts.nfolds
	ROOT_DIR  = opts.root_dir
	BLOCK_DIR  = opts.block_dir
	ROUNDNAME  = opts.round
	polyA_file = opts.polyAfile
	OUT	   = opts.out
	############Global  Parameters ############
	prep_data(ROOT_DIR,BLOCK_DIR,polyA_file,ROUNDNAME,NUM_FOLDS,OUT)
