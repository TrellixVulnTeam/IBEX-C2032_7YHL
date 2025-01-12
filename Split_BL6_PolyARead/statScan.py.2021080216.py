#!/usr/bin/env python -w
#
#
#Update 2021/04/28 Check peak
import re
import argparse


def getInfo(INFO):
	block_info_dict = dict()
	with open(INFO,'r') as f:
		#line = f.readline() ###skip header
		for line in f:
			baseName,start,end = line.rstrip('\n').split('\t')[0:3]
			start = int(start)
			end   = int(end)
			block_info_dict[baseName] = [start,end]
	return block_info_dict

def getPredictPos(INP,threshold):
	pas_pos_dict = dict()
	with open(INP,'r') as f:
		line = f.readline() ####skip header
		for line in f:
			#pas_id,start,end,length,max_score,area =line.rstrip('\n').split('\t')
			pas_id,start,end,length,max_score,area  = [int(x) if re.match("[1-9]\d*$",x) else float(x) if re.match('[1-9]\d*\.\d*|0\.\d*[1-9]\d*$',x) else x for x in line.rstrip('\n').split('\t')]
			#chromosome,coor,strand = pas_id.split(':')
			#coor = int(coor)^a
			coor = (start+end)/2
			#if(length > threshold):
			if(area > threshold):
				pas_pos_dict[coor] = [start,end,max_score,length,area]
	return pas_pos_dict

def mapToGroundTruth(PAS,predict_pas_pos_dict,CHR,SRD,lower_bound,upper_bound,polyASeqRCThreshold,RNASeqRCThreshold,usageThreshold):
	groundTruth = 0
	nearest  = dict()
	with open(PAS,'r') as f:
		line = f.readline() ####skip header
		for line in f:
			pas_id,pas_type,chromosome,pos,strand,symbol,usage,polyASeqRc,_,_,RNASeqRc  = [int(x) if re.match("[1-9]\d*$",x) else float(x) if re.match('[1-9]\d*\.\d*|0\.\d*[1-9]\d*$',x) else x for x in line.rstrip('\n').split('\t')[0:11]]
			if(polyASeqRc<polyASeqRCThreshold or RNASeqRc<RNASeqRCThreshold or usage<usageThreshold):
				continue

			if(chromosome == CHR and strand == SRD and pos>=lower_bound and pos<=upper_bound):
				groundTruth+=1
				for coor,val in predict_pas_pos_dict.items():
					if(coor not in nearest.keys() or abs(coor-pos)<abs(nearest[coor][1])):
						nearest[coor] = [pas_id,coor-pos,pos]

	return groundTruth,nearest


def stat(nearest,predict_pas_pos_dict,out,CHR,SRD):
	tp25=0
	tp50=0
	tp100=0
	inpeak=0
	OUT=open(out,'w')
	OUT.write('predict_pas_id\tgroundTruth_pas_id\tdistance\tpeak_start\tpeak_end\ttruth\tmax_score\tlength\tarea\n')
	for pos,val in nearest.items():
		peak_start,peak_end,max_score,length,area = predict_pas_pos_dict[pos]
		if(abs(val[1])<=25 or (val[2]>=peak_start and val[2]<=peak_end)):
			inpeak+=1
			OUT.write('%s:%d:%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n'%(CHR,pos,SRD,val[0],val[1],peak_start,peak_end,"Yes",max_score,length,area))
		else:
			OUT.write('%s:%d:%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n'%(CHR,pos,SRD,val[0],val[1],peak_start,peak_end,"No",max_score,length,area))

		if(abs(val[1])<100):
			tp100+=1
			if(abs(val[1])<50):
				tp50+=1
				if(abs(val[1])<25):
					tp25+=1
	OUT.close()
	return tp25,tp50,tp100,inpeak

if __name__ == "__main__":
	### Argument Parser
	parser = argparse.ArgumentParser()
	parser.add_argument('--testid', help='test id ')
	parser.add_argument('--baseName', help='baseName')
	parser.add_argument('--info', help='block information')
	parser.add_argument('--threshold', type=int,help='peak length lower than threshold will be fiter out')
	parser.add_argument('--pasfile', help='pas usage file')
	parser.add_argument('--polyASeqRCThreshold',type=float, help='polyA Seq reac count threshold')
	parser.add_argument('--RNASeqRCThreshold', type=float, help='RNA seq coverage threshold')
	parser.add_argument('--usageThreshold', type=float,help='usage threshold')
	args = parser.parse_args()

	testid = args.testid
	baseName = args.baseName
	threshold = args.threshold
	info = args.info
	pasfile=args.pasfile
	polyASeqRCThreshold = args.polyASeqRCThreshold
	RNASeqRCThreshold  =  args.RNASeqRCThreshold
	usageThreshold     = args.usageThreshold

	INP='scan/'+testid+'.'+baseName+'.peak'+str(threshold)+'.txt'
	INFO=info
	PAS=pasfile
	OUT='map/'+testid+'.'+baseName+'.peak'+str(threshold)+'.txt'
	STAT='Stat/'+testid+'.'+baseName+'.peak'+str(threshold)+'.txt'


	#INP="K562_Merge.pAs.single_kermax6.K562_Merge_aug8_SC_p4r9u0.05_4-0101.chr10_+_0.txt.peak12.txt"
	#INFO="../Split_BL6/K562_Chen_data/Blocks/info.txt"
	#PAS="usage_data/K562_Merge.pAs.usage.txt"
	#OUT="test.txt"
	#STAT="stat.txt"
	#threshold = 12
	#polyASeqRCThreshold = 4
	#RNASeqRCThreshold = 9
	#usageThreshold = 0.05

	#baseName = INP.split('.')[-4]
	CHR,SRD,_ = baseName.split('_')

	block_info_dict = getInfo(INFO)
	lower_bound,upper_bound = block_info_dict[baseName]

	pas_pos_dict = getPredictPos(INP,threshold)

	groundTruth,nearest = mapToGroundTruth(PAS,pas_pos_dict,CHR,SRD,lower_bound,upper_bound,polyASeqRCThreshold,RNASeqRCThreshold,usageThreshold)

	tp25,tp50,tp100,inpeak = stat(nearest,pas_pos_dict,OUT,CHR,SRD)
	totalPredict = len(nearest.keys())

	OUT=open(STAT,'w')
	OUT.write("%s\t%d\t%d\t%d\t%d\t%d\t%d\n"%(baseName,inpeak,tp25,tp50,tp100,groundTruth,totalPredict))
	OUT.close()
