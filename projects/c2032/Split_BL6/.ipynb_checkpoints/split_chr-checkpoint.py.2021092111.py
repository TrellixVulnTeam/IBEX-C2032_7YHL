#!/usr/bin/env python
# coding: utf-8

import os
import glob
from collections import OrderedDict,defaultdict
import pipes
import pprint
import tempfile
import re



def binary_locate(array,ele,start,end):
    middle = (end+start)//2
    if(end-start>1):
        if(array[middle]<ele):
            return binary_locate(array,ele,middle,end)
        elif(array[middle+1]>ele):
            return binary_locate(array,ele,start,middle)
        else:
            return middle,middle+1
    else:
        return middle,middle+1
    

def split(file):
    num_lines = sum(1 for line in open(file))
    num_blocks = round(num_lines/Fixed_length)
    len_blocks = num_lines/num_blocks
    
    f= open(file,'r')
    pre_pos = 0
    dict_line = OrderedDict()
    #dict_line = dict()
    count = 0
    separate_num=0
    save_block = 0
    start = 0
    
    for i, line in enumerate(f):
        line = line.rstrip('\n')
        if(i==0):
            continue ###Skip header
        chromosome,pos,strand = line.split('\t')[0].split(':')
        pos = int(pos)
        count += 1
        if(i==1):
            start=pos
        if(count>len_blocks and pos-pre_pos>1000 and save_block<num_blocks-1):
            array = Gene_Loc[chromosome+strand]
            index1,index2 = binary_locate(array,pre_pos,0,len(array)-1)
            if(index1%2==1 and index2%2==0):
                ww = open(root_dir+'/Blocks/%s_%s_%d'%(chromosome,strand,save_block),'w')
                print('writing file '+root_dir+'/Blocks/%s_%s_%d_%d-%d'%(chromosome,strand,save_block,start,pre_pos))
                info.write('%s_%s_%d\t%d\t%d\t%d\t%d\n'%(chromosome,strand,save_block,start,pre_pos,pre_pos-start,count))
                #print('%s_%s_%d\t%d\t%d\t%d\t%d\n'%(chromosome,strand,save_block,start,pre_pos,pre_pos-start,count))
                for key,val in dict_line.items():
                    ww.write('%s\n'%val)
                ww.close()
                dict_line.clear()
                count = 0
                save_block += 1
                start  = pos
            
        
        dict_line[pos] = line
        pre_pos = pos
        
    out = open(root_dir+'/Blocks/%s_%s_%d'%(chromosome,strand,save_block),'w')
    print('writing file '+root_dir+'/Blocks/%s_%s_%d_%d-%d'%(chromosome,strand,save_block,start,pre_pos))
    info.write('%s_%s_%d\t%d\t%d\t%d\t%d\n'%(chromosome,strand,save_block,start,pre_pos,pre_pos-start,count))
    for key,val in dict_line.items():
        out.write('%s\n'%(val))
    out.close()

info.close()

if __name__ == "main":
    ####Fixed length 5e5 = 200 blocks. 
    root_dir = 'bl6_rep1_data'
    ####Fixed length 1e6 = 100 blocks. 
    ####Fixed length 5e5 = 200 blocks. 
    Fixed_length = 2e6
    ens_file = "102.gtf.gz"
    
    p = pipes.Template()
    p.append("zcat", '--')
    Gene_Loc = defaultdict(list)

    f = p.open(ens_file, 'r')
    for line in f.readlines():
        if re.match('^#',line):
            continue
        line = line.rstrip('\n')
        data = line.split('\t')
        if(data[2] == 'gene'):
            Gene_Loc['chr'+data[0]+data[6]].append(int(data[3]))
            Gene_Loc['chr'+data[0]+data[6]].append(int(data[4]))
    
    total = 0
    info = open(root_dir+'/Blocks/info.txt','a')
    split(file)
    #info.write('ID\tstart\tend\tlength\tsites_num\n')