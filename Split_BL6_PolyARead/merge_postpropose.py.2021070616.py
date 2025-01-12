#!/usr/bin/env python3
from get_files import get_files
import argparse
import re
from os.path import isfile
import numpy as np

parser = argparse.ArgumentParser()
parser.add_argument('--root_dir', help='Directory of scanTranscriptome files')
parser.add_argument('--round',help='Round of training')
parser.add_argument('--maxPoint', default=12, type=int, help='Threshold of maxPoint')
parser.add_argument('--penality', default=1, type=int, help='penelity score of predicted negative ')
parser.add_argument('--trainid', default=None, help='Training id')
parser.add_argument('--sets',choices=('all','train','valid','test'),help='Determine which sets from trian,valid and test')
opts = parser.parse_args()


ROOT_DIR  = opts.root_dir
ROUNDNAME  = opts.round
Round = int(ROUNDNAME[-1])
maxPoint = opts.maxPoint
penality = opts.penality
trainid  = opts.trainid
SET = opts.sets

print('Report of '+SET+'set')

train_sets,valid_sets,test_sets = get_files(ROOT_DIR,Round)
if(SET  == 'all'):
	sets = np.concatenate((train_sets,valid_sets,test_sets))
elif(SET  == 'train'):
	sets = train_sets

elif(SET == 'valid'):
	sets = valid_sets

elif(SET == 'test'):
	sets = test_sets


RealNum25=0
RealNum50=0
RealNum100=0
ground_truth=0
precise25=0
precise50=0
precise100=0
predict=0



for filepath in sets:
	baseName = filepath.split('/')[-1]
	statpath = 'Stat/'+trainid+'.'+baseName+'.txt.bidirection.'+str(maxPoint)+'.'+str(penality)+'.txt'

	if not isfile(statpath):
		continue
	f= open(statpath,'r')
	for i, line in enumerate(f):
		line = line.rstrip('\n')
		if re.match('ground',line):
			_,tp25,tp50,tp100,total = line.split('\t')
			RealNum25+= int(tp25)
			RealNum50+= int(tp50)
			RealNum100+= int(tp100)
			ground_truth += int(total)
		elif re.match('precise',line):
			_,pre25,pre50,pre100,pre = line.split('\t')
			precise25 += int(pre25)
			precise50 += int(pre50)
			precise100 += int(pre100)
			predict += int(pre)

	f.close()


recall25 = RealNum25/ground_truth
recall50 = RealNum50/ground_truth
recall100 = RealNum100/ground_truth
print("groundTruth:\t%d\t%d\t%d\t%d"%(RealNum25,RealNum50,RealNum100,ground_truth))
print("recall:\t%.3f\t%.3f\t%.3f"%(recall25,recall50,recall100))

precision25 = RealNum25/predict
precision50 = RealNum50/predict
precision100 = RealNum100/predict
print("Real precision:\t%.3f\t%.3f\t%.3f"%(precision25,precision50,precision100))


percent25 = precise25/predict
percent50 = precise50/predict
percent100 = precise100/predict
print("precise:\t%d\t%d\t%d\t%d"%(precise25,precise50,precise100,predict))
print("precision:\t%.3f\t%.3f\t%.3f"%(percent25,percent50,percent100))

print("%d\t%d\t%d\t%.3f\t%.3f"%(ground_truth,predict,RealNum25,recall25,precision25))
