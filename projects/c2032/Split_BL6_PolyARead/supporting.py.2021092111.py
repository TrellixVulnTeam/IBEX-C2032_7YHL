import numpy as np
import re

############ Parameters ############
PATCH_SIZE = 10
SEQ_LEN = 176

#NUM_CHANNELS = 4
NUM_LABELS = 2
############ **************** ############

def shuffle(dataset, labels, pasid, randomState=None):
	"""
	Shuffle sequences and labels jointly
	"""
	if randomState is None:
		permutation = np.random.permutation(labels.shape[0])
	else:
		print(labels.shape[0])
		permutation = randomState.permutation(labels.shape[0])
	shuffled_data = dataset[permutation,:,:]
	shuffled_labels = labels[permutation]
	shuffled_pasid = pasid[permutation]
	return shuffled_data, shuffled_labels,shuffled_pasid

def get_dataDp(data_path, label,alphabet):
	"""
	Inner Product
	Process all files in the input directory to read sequences.
	Sequences are encoded with one-hot.
	data_root: input directory
	label: the label (True or False) for the sequences in the input directory
	"""
	data = []
	labels = []
	pasid = []
	with open(data_path, 'r') as f:
		next(f)
		for line in f:
			line = line.strip('\n')
			array = line.split('\t')
			base = list(array[7])
			base=base[0:SEQ_LEN]
			COVERAGE = np.array(array[8:SEQ_LEN+8]).astype(np.float32)
			COVERAGE=np.array([x-min(COVERAGE) for x in COVERAGE])/(max(COVERAGE)-min(COVERAGE))
			seq_len = len(base)
			seq = np.array(base, dtype = '|U1').reshape(-1, 1)
			seq_data = (seq == alphabet).astype(np.float32)
			merge_data = []
			for (idx,val) in enumerate(seq_data):
				merge_data.append(val*COVERAGE[idx])
				#merge_data.append(val*(COVERAGE[idx]+1))
			merge_data = np.array(merge_data)
			data.append(merge_data)
			pasid.append(label[0:3]+array[0])
	seq_dim = merge_data.shape[1]
	seq_len = len(base)
	data = np.stack(data).reshape([-1, seq_len, seq_dim])
	pasid=np.array(pasid)
	if label == "Positive":
		labels = np.zeros(data.shape[0])
	else:
		labels = np.ones(data.shape[0])
	print('Read %d %s sequences from %s'%(labels.shape[0],label, data_path))
	print('Sequences length is %d,Sequences dimension is %d'%(seq_len,seq_dim))
	return data, labels, pasid

def get_dataCat(data_path, label,alphabet):
	"""
	outer product
	Process all files in the input directory to read sequences.
	Sequences are encoded with one-hot.
	data_root: input directory
	label: the label (True or False) for the sequences in the input directory
	"""
	data = []
	labels = []
	pasid = []
	with open(data_path, 'r') as f:
		next(f)
		for line in f:
			line = line.strip('\n')
			array = line.split('\t')
			base = list(array[7])
			base=base[0:SEQ_LEN]
			COVERAGE = np.array(array[8:SEQ_LEN+8]).astype(np.float32)
			######Min-Max Norm
			COVERAGE=np.array([x-min(COVERAGE) for x in COVERAGE])/(max(COVERAGE)-min(COVERAGE))
			seq_len = len(base)
			seq = np.array(base, dtype = '|U1').reshape(-1, 1)
			seq_data = (seq == alphabet).astype(np.float32)
			read_data = np.stack(COVERAGE).reshape([-1,1])
			merge_data = np.hstack((seq_data,read_data))
			data.append(merge_data)
			pasid.append(label[0:3]+array[0])
	seq_dim = merge_data.shape[1]
	seq_len = len(base)
	data = np.stack(data).reshape([-1, seq_len, seq_dim])
	pasid=np.array(pasid)
	if label == "Positive":
		labels = np.zeros(data.shape[0])
	else:
		labels = np.ones(data.shape[0])
	print('Read %d %s sequences from %s'%(labels.shape[0],label, data_path))
	print('Sequences length is %d,Sequences dimension is %d'%(seq_len,seq_dim))
	return data, labels, pasid

def get_dataRc(data_path, label,alphabet):
	"""
	only read count data
	Process all files in the input directory to read sequences.
	Sequences are encoded with one-hot.
	data_root: input directory
	label: the label (True or False) for the sequences in the input directory
	"""
	data = []
	labels = []
	pasid = []
	seq_len=0

	with open(data_path, 'r') as f:
		next(f)
		for line in f:
			line = line.strip('\n')
			array = line.split('\t')
			base = list(array[7])
			base=base[0:SEQ_LEN]
			COVERAGE=np.array(array[8:SEQ_LEN+8]).astype(np.float32)
			COVERAGE=np.array([x-min(COVERAGE) for x in COVERAGE])/(max(COVERAGE)-min(COVERAGE))
			seq_len = len(base)
			seq = np.array(base, dtype = '|U1').reshape(-1, 1)
			seq_data = (seq == alphabet).astype(np.float32)
			read_data = np.stack(COVERAGE).reshape([-1,1]).astype(np.float32)
			data.append(read_data)
			pasid.append(label[0:3]+array[0])
	seq_dim = alphabet.shape[0]
	data = np.stack(data).reshape([-1, seq_len, 1])
	pasid=np.array(pasid)
	if label == "Positive":
		labels = np.zeros(data.shape[0])
	else:
		labels = np.ones(data.shape[0])
	print('Read %d %s sequences from %s'%(labels.shape[0],label, data_path))
	print('Sequences length is %d,Sequences dimension is %d'%(seq_len,seq_dim))
	return data, labels, pasid

def get_dataSeq(data_path, label,alphabet):
	"""
	Process all files in the input directory to read sequences.
	Sequences are encoded with one-hot.
	data_root: input directory
	label: the label (True or False) for the sequences in the input directory
	"""
	data = []
	labels = []
	pasid = []
	seq_len=0

	with open(data_path, 'r') as f:
		next(f)
		for line in f:
			line = line.strip('\n')
			array = line.split('\t')
			base = list(array[7])
			base=base[0:SEQ_LEN]
			seq_len = len(base)
			seq = np.array(base, dtype = '|U1').reshape(-1, 1)
			seq_data = (seq == alphabet).astype(np.float32)
			data.append(seq_data)
			pasid.append(label[0:3]+array[0])
	seq_dim = alphabet.shape[0]
	data = np.stack(data).reshape([-1, seq_len, seq_dim])
	pasid=np.array(pasid)
	if label == "Positive":
		labels = np.zeros(data.shape[0])
	else:
		labels = np.ones(data.shape[0])
	print('Read %d %s sequences from %s'%(labels.shape[0],label, data_path))
	print('Sequences length is %d,Sequences dimension is %d'%(seq_len,seq_dim))
	return data, labels, pasid

def get_data(data_path, label,alphabet):
	"""
	Process all files in the input directory to read sequences.
	Sequences are encoded with one-hot.
	data_root: input directory
	label: the label (True or False) for the sequences in the input directory
	"""
	data = []
	with open(data_path, 'r') as f:
		for line in f:
			line = list(line.strip('\n'))
			seq_len = len(line)
			seq = np.array(line, dtype = '|U1').reshape(-1, 1)
			seq_data = (seq == alphabet).astype(np.float32)
			data.append(seq_data)
	seq_dim = alphabet.shape[0]
	data = np.stack(data).reshape([-1, seq_len, 1, seq_dim])
	if label == "Positive":
		labels = np.zeros(data.shape[0])
	else:
		labels = np.ones(data.shape[0])
	print('Read %d %s sequences from %s'%(labels.shape[0],label, data_path))
	print('Sequences length is %d,Sequences dimension is %d'%(seq_len,seq_dim))
	return data, labels


def data_split(pos_data, pos_labels, pos_pasid, neg_data, neg_labels, neg_pasid, NUM_FOLDS, split):
	"""
	Split the dataset into NUM_FOLDS folds.
	Then split train, valid, and test sets according to the input dict split.
	"""
	pos_data_folds = np.array_split(pos_data, NUM_FOLDS)
	neg_data_folds = np.array_split(neg_data, NUM_FOLDS)
	pos_label_folds = np.array_split(pos_labels, NUM_FOLDS)
	neg_label_folds = np.array_split(neg_labels, NUM_FOLDS)
	pos_pasid_folds = np.array_split(pos_pasid, NUM_FOLDS)
	neg_pasid_folds = np.array_split(neg_pasid, NUM_FOLDS)

	train_pos_data = np.concatenate([pos_data_folds[i] for i in split['train']], axis=0)
	train_pos_labels = np.concatenate([pos_label_folds[i] for i in split['train']], axis=0)
	train_pos_pasid = np.concatenate([pos_pasid_folds[i] for i in split['train']], axis=0)
	valid_pos_data = np.concatenate([pos_data_folds[i] for i in split['valid']], axis=0)
	valid_pos_labels = np.concatenate([pos_label_folds[i] for i in split['valid']], axis=0)
	valid_pos_pasid = np.concatenate([pos_pasid_folds[i] for i in split['valid']], axis=0)
	#test_pos_data = np.concatenate([pos_data_folds[i] for i in split['test']], axis=0)
	#test_pos_labels = np.concatenate([pos_label_folds[i] for i in split['test']], axis=0)
	#test_pos_pasid = np.concatenate([pos_pasid_folds[i] for i in split['test']], axis=0)

	train_neg_data = np.concatenate([neg_data_folds[i] for i in split['train']], axis=0)
	train_neg_labels = np.concatenate([neg_label_folds[i] for i in split['train']], axis=0)
	train_neg_pasid = np.concatenate([neg_pasid_folds[i] for i in split['train']], axis=0)
	valid_neg_data = np.concatenate([neg_data_folds[i] for i in split['valid']], axis=0)
	valid_neg_labels = np.concatenate([neg_label_folds[i] for i in split['valid']], axis=0)
	valid_neg_pasid = np.concatenate([neg_pasid_folds[i] for i in split['valid']], axis=0)
	#test_neg_data = np.concatenate([neg_data_folds[i] for i in split['test']], axis=0)
	#test_neg_labels = np.concatenate([neg_label_folds[i] for i in split['test']], axis=0)
	#test_neg_pasid = np.concatenate([neg_pasid_folds[i] for i in split['test']], axis=0)

	train_data = np.concatenate((train_pos_data, train_neg_data), axis=0)
	valid_data = np.concatenate((valid_pos_data, valid_neg_data), axis=0)
	#test_data = np.concatenate((test_pos_data, test_neg_data), axis=0)
	train_labels = np.concatenate((train_pos_labels, train_neg_labels), axis=0)
	valid_labels = np.concatenate((valid_pos_labels, valid_neg_labels), axis=0)
	#test_labels = np.concatenate((test_pos_labels, test_neg_labels), axis=0)
	train_pasid = np.concatenate((train_pos_pasid, train_neg_pasid), axis=0)
	valid_pasid = np.concatenate((valid_pos_pasid, valid_neg_pasid), axis=0)
	#test_pasid = np.concatenate((test_pos_pasid, test_neg_pasid), axis=0)

	data = {}
	randomState = np.random.RandomState(0)
	data['train_dataset'], data['train_labels'], data['train_pasid'] = shuffle(train_data, train_labels, train_pasid,randomState)
	data['valid_dataset'], data['valid_labels'], data['valid_pasid'] = shuffle(valid_data, valid_labels, valid_pasid,randomState)
	#data['test_dataset'], data['test_labels'], data['test_pasid'] = shuffle(test_data, test_labels, test_pasid,randomState)

	return data


def pad_dataset(dataset, labels=[]):
    ''' Pad sequences to (length + 2*DEPTH - 2) wtih 0.25 '''
    new_dataset = np.ones([dataset.shape[0], dataset.shape[1]+2*PATCH_SIZE-2, dataset.shape[2], dataset.shape[3]], dtype = np.float32) * 0.25
    new_dataset[:, PATCH_SIZE-1:-(PATCH_SIZE-1), :, :] = dataset
    if labels != []:
        labels = (np.arange(NUM_LABELS) == labels[:,None]).astype(np.float32)
    return new_dataset, labels


def get_accuracy(predictions, pasid):
	predictions = np.argmax(predictions, 1)
	true_pos=0
	true_neg=0
	false_pos=0
	false_neg=0
	TPR=0.0
	FDR=0.0
	for idx,pred in enumerate(predictions):
		if(pred ==0 and re.match('Pos',pasid[idx])):
			true_pos +=1
		elif(pred ==0 and re.match('Neg',pasid[idx])):
			false_pos +=1
		elif(pred ==1 and re.match('Pos',pasid[idx])):
			false_neg += 1
		elif(pred ==1 and re.match('Neg',pasid[idx])):
			true_neg +=1
	TPR = true_pos/(true_pos+false_neg)*100 if (true_pos+false_neg) >0 else 0
	FDR = false_pos/(true_pos+false_pos)*100

	print('TP: %d, FP: %d' %(true_pos,false_pos))
	print('FN: %d, TN: %d' %(false_neg,true_neg))
	print('TPR: %.1f%%' %TPR)
	print('FDR: %.1f%%' %FDR)
	return TPR, FDR
