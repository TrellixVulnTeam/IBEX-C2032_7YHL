#!/usr/bin/env python
# coding: utf-8

import os,sys
import glob
from collections import OrderedDict,defaultdict
import pipes
import pprint
import tempfile
import re
import argparse
#from pyfaidx import Fasta


def write_file(root_dir,dict_line,chromosome,strand,save_block,start,pre_pos,count,reference,window,name):
	ww = open(root_dir+'/%s.%s_%s_%d'%(name,chromosome,strand,save_block),'w')
	print('writing file '+root_dir+'/%s_%s_%d_%d-%d'%(chromosome,strand,save_block,start,pre_pos))
	pre_pos = 1
	pos_array = list(dict_line.keys())
	#for pos,val in dict_line.items():
	for i,pos in enumerate(pos_array):
		val = dict_line[pos]
	
		if(pos-pre_pos>=window):
			pre_pos = pos-window+1
		while(pos-pre_pos>=1):
			if pre_pos not in dict_line.keys():
				pre_base = reference[pre_pos-1]
				if(pre_base != 'N'):
					ww.write('%s:%d:%s\t%d\t%s\n'%(chromosome,pre_pos,strand,0,pre_base))
			pre_pos += 1
			
		ww.write('%s:%d:%s\t%s\n'%(chromosome,pos,strand,val))
		pre_pos = pos
		
		if(i < len(pos_array)-1):
			post_pos = pos_array[i+1]
			if(post_pos-pos>=window):
				post_pos = pos+window-1
		else:
			post_pos = pos+window-1
		while(post_pos - pre_pos>=1):
			if pre_pos not in dict_line.keys():
				pre_base = reference[pre_pos-1]
				if(pre_base != 'N'):
					ww.write('%s:%d:%s\t%d\t%s\n'%(chromosome,pre_pos,strand,0,pre_base))
			pre_pos += 1
			
	dict_line.clear()
	ww.close()
	

def split(root_dir,block_length,input_file,reference,window,chromosome,strand,name,depth):
	
	wig_file = open(input_file, "r")
	lines = wig_file.readlines()
	wig_file.close()
	 
	num_lines = len(lines)
	num_blocks = num_lines/block_length
	len_blocks = num_lines/num_blocks
	
	pre_pos = 0
	dict_line = OrderedDict()
	count = 0
	separate_num=0
	save_block = 0
	start = 0
	
	for i, line in enumerate(lines):
		line = line.rstrip('\n')
		if(i==0):
			continue ###Skip header
		pos,rpm = line.split('\t')
		pos = int(pos)
		base = reference[pos-1]
		if(base == 'N'):
			continue
		rpm = float(rpm)
		rpm /= depth ####NORMALIZED TO RPM
		if(rpm < 0):
			rpm = -rpm
		count += 1
		if(i==1):
			start=pos
		if(count>len_blocks and pos-pre_pos>1000 and save_block<num_blocks-1):
			write_file(root_dir,dict_line,chromosome,strand,save_block,start,pre_pos,count,reference,window,name)
			count = 0
			save_block += 1
			start  = pos
			
		
		dict_line[pos] = "%.5f\t%s"%(rpm,base)
		pre_pos = pos
		
	write_file(root_dir,dict_line,chromosome,strand,save_block,start,pre_pos,count,reference,window,name)
	

def get_genome_sequence(fa_file):
	f = open(fa_file,"r")
	line = f.readline()
	line = line.rstrip('\n')
	f.close()
	return line

def split_chr(root_dir,input_file,strand):
	with open(input_file, "r") as wig_file:
		for line in wig_file.readlines():
			line = line.rstrip('\n')
			#if('variableStep' in line):
			if not line[0].isdigit():
				info = line.split(' ')
				chromosome = info[1].split('chrom=')[1]
				if ('chr' not in chromosome):
					chromosome = 'chr'+chromosome
				if(len(chromosome)>5 or 'Y' in chromosome or 'M' in chromosome):
					continue

				out = open(root_dir+'/%s_%s.wig'%(chromosome,strand),'w')
			else:
				out.write("%s\n"%line)

def split_chr_bedGraph(root_dir,input_file,strand,window):
	chr_dict = dict()
	with open(input_file, "r") as bg_file:
		lines = bg_file.readlines()
		#for line in bg_file.readlines():
		for i,line in enumerate(lines):
			line = line.rstrip('\n')
			chromosome,start,end,val = line.split('\t')
			if ('chr' not in chromosome):
				chromosome = 'chr'+chromosome
			if(len(chromosome)>5 or 'Y' in chromosome or 'M' in chromosome):
				continue
			pos1 = int(start)+1
			pos2 = int(end)+1

			if chromosome not in chr_dict.keys():
				chr_dict[chromosome] = ''
				out = open(root_dir+'/%s_%s.wig'%(chromosome,strand),'w')
				for pos in range(pos1,pos2):
					out.write("%d\t%s\n"%(pos,val))
			else:
				for pos in range(pos1,pos2):
					out.write("%d\t%s\n"%(pos,val))

def split_chr_bedGraph2(root_dir,input_file,strand,window,block_length,fa_file,depth):
	chr_dict = dict()
	blocks = dict()
	block = []
	reference = dict()
	pro_pos = 0
	start_pos = 0
	block_num = 0
	count = 0
	with open(input_file, "r") as bg_file:
		lines = bg_file.readlines()
		#for line in bg_file.readlines():
		for i,line in enumerate(lines):
			line = line.rstrip('\n')
			chromosome,start,end,val = line.split('\t')
			if(len(chromosome)>5 or 'Y' in chromosome or 'M' in chromosome):
				continue
			val = float(val)
			pos1 = int(start)+1
			pos2 = int(end)+1

			extend1 = window
			extend2 = window
			if(i>0 and i< len(line)-1):
				pre_line = lines[i-1].rstrip('\n')
				nex_line = lines[i+1].rstrip('\n')
				pre_chr,_,pre_pos,_ = pre_line.split('\t')
				nex_chr,nex_pos,_,_ = nex_line.split('\t')
				pre_pos = int(pre_pos)+1
				nex_pos = int(nex_pos)+1
				if(pre_chr == chromosome and pos1-pre_pos<2*window):
					if(pos1-pre_pos<window):
						extend1 = 0
					else:
						extend1 = pos1-pre_pos-window
				if(nex_chr == chromosome and nex_pos-pos2<window):
					extend2 = nex_pos-pos2

				#if(pos1 == '5019290'):
				#	print(extend1,extend2)

			if ('chr' not in chromosome):
				chromosome = 'chr'+chromosome
			if chromosome not in chr_dict.keys():
				chr_dict[chromosome] = ''
				reference = get_genome_sequence('%s.%s.fa'%(fa_file,chromosome))
				block = []
				for pos in range(pos1-extend1,pos2+extend2):
					base = reference[pos-1]
					if(base == 'N'):
						continue
					rpm = 0
					if(pos>=pos1 and pos<pos2):
						rpm = val/depth
					block.append(('%s:%s:%s'%(chromosome,pos,strand),rpm,base))
					count += 1
			else:
				if(count > block_length and pos1-pre_pos >1000):
					blocks['%s_%s_%s'%(chromosome,strand,block_num)] = block
					block_num += 1
					block = []
					start_pos = pos1
					count = 0

				for pos in range(pos1-extend1,pos2+extend2):
					base = reference[pos-1]
					if(base == 'N'):
						continue
					rpm = 0
					if(pos>=pos1 and pos<pos2):
						rpm = val/depth
					block.append(('%s:%s:%s'%(chromosome,pos,strand),rpm,base))
					count += 1
			pre_pos = pos2
	for key,val in blocks.items():
		ww = open('%s'%(key),'w')
		for item in val:
			ww.write('%s\t%s\t%s\n'%(item[0],item[1],item[2]))
		ww.close()
	#return blocks

def args():
	parser = argparse.ArgumentParser()
	parser.add_argument('--out_dir', default=None, help='out dir')
	parser.add_argument('--input_file', default=None, help='unstranded wig file')
	parser.add_argument('--input_plus', default=None, help='plus strand wig file')
	parser.add_argument('--input_minus', default=None, help='minus strand wig file')
	parser.add_argument('--fa_file',default=None,help='path to one line fa file')
	parser.add_argument('--keep_temp',default=None,help='if you want to keep temporary file, set to "yes"')
	parser.add_argument('--window', default=201, type=int, help='input length')
	parser.add_argument('--name', default='sample',help='sample name')
	parser.add_argument('--depth', default=1, type=float,help='total number of mapped reads( in millions)')
  
	argv = parser.parse_args()

	out_dir = argv.out_dir
	input_file = argv.input_file
	input_plus = argv.input_plus
	input_minus = argv.input_minus
	fa_file = argv.fa_file
	keep_temp =  argv.keep_temp
	window = argv.window
	name= argv.name
	depth = argv.depth

	return out_dir,input_file,input_plus,input_minus,fa_file,keep_temp,window,name,depth


def Generate_windows(root_dir,input_file,input_plus,input_minus,fa_file,keep_temp,window,name,depth):
	block_length = 1e6
	window /= 1.5 ####No need more extendsion
	window = int(window)
	
	if(root_dir[-1] == '/'):
		root_dir = root_dir[0:-1]
	if not os.path.exists(root_dir):
		os.makedirs(root_dir) 

	root_dir = root_dir+'/data'
	if not os.path.exists(root_dir):
		os.makedirs(root_dir) 


	if(input_file is not None):
		strand = '+'
		if('wig' in input_file):
			split_chr(root_dir,input_file,strand)
		elif('bedgraph' in input_file.lower()):
			split_chr_bedGraph(root_dir,input_file,strand,window)
		else:
			sys.exit("input file extension should be wig or bedGraph")


		wig_chr_files = glob.glob(root_dir+"/*"+strand+".wig")
		for wig_file in wig_chr_files:
			basename = wig_file.split('/')[-1]
			chromosome = basename.split('_')[0]
			reference = get_genome_sequence('%s.%s.fa'%(fa_file,chromosome))
			split(root_dir,block_length,wig_file,reference,window,chromosome,strand,name,depth)
		block_files = glob.glob(root_dir+"/*+*")
		for block in block_files:
			minus_block = block.replace('+','-')
			os.system('cp %s %s'%(block,minus_block))
	if(input_plus is not None):
		strand = '+'
		if('wig' in input_plus):
			split_chr(root_dir,input_plus,strand)
		elif('bedgraph' in input_plus.lower()):
			#split_chr_bedGraph(root_dir,input_plus,strand,window)
			split_chr_bedGraph2(root_dir,input_plus,strand,window,block_length,fa_file,depth)
		else:
			sys.exit("input file extension should be wig or bedGraph")
		#wig_chr_files = glob.glob(root_dir+"/*"+strand+".wig")
		#for wig_file in wig_chr_files:
		#	basename = wig_file.split('/')[-1]
		#	chromosome = basename.split('_')[0]
		#	reference = get_genome_sequence('%s.%s.fa'%(fa_file,chromosome))
		#	split(root_dir,block_length,wig_file,reference,window,chromosome,strand,name,depth)
	if(input_minus is not None):
		strand = '-'
		if('wig' in input_minus):
			split_chr(root_dir,input_minus,strand)
		elif('bedgraph' in input_minus.lower()):
			#split_chr_bedGraph(root_dir,input_minus,strand,window)
			split_chr_bedGraph2(root_dir,input_minus,strand,window,block_length,fa_file,depth)
		else:
			sys.exit("input file extension should be wig or bedGraph")
		#wig_chr_files = glob.glob(root_dir+"/*"+strand+".wig")
		#for wig_file in wig_chr_files:
		#	basename = wig_file.split('/')[-1]
		#	chromosome = basename.split('_')[0]
		#	reference = get_genome_sequence('%s.%s.fa'%(fa_file,chromosome))
		#	split(root_dir,block_length,wig_file,reference,window,chromosome,strand,name,depth)
	print("Finished merging coverage and sequence information")
	os.system('rm *%s/*.wig'%root_dir)



if __name__ == "__main__":
	#print(args())
	Generate_windows(*args())

