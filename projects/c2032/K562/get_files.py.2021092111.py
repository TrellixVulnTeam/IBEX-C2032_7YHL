#!/usr/bin/env python3

import numpy as np
import os
import sys
import argparse
import glob
from sklearn.model_selection import KFold

def get_files(root_dir,Round):
	Fold = 5
	files = glob.glob(root_dir+"/chr*")
	files = np.array(sorted(files))
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
if __name__ == "__main__":

	parser = argparse.ArgumentParser()
	parser.add_argument('--root_dir', help='Directory of files containing positive and negative files')
	parser.add_argument('--round',help='Round of training')
	parser.add_argument('--sets',choices=('train','valid','test'),help='Determine which sets from trian,valid and test')
	opts = parser.parse_args()


	ROOT_DIR  = opts.root_dir
	ROUNDNAME  = opts.round
	SET = opts.sets


	Round = int(ROUNDNAME[-1])
	train_sets,valid_sets,test_sets = get_files(ROOT_DIR,Round)

	if(SET  == 'train'):
		sets = train_sets

	elif(SET == 'valid'):
		sets = valid_sets

	elif(SET == 'test'):
		sets = test_sets

	for filepath in sets:
		print(filepath,end=' ')
