from PolyAModel import *
import os, sys, copy, getopt, re, argparse
import random
from datetime import datetime
import pandas as pd 
import numpy as np
from tensorflow.keras.callbacks import TensorBoard
from tensorflow.keras.callbacks import ModelCheckpoint
from prep_data import prep_data,DataGenerator

print("Num GPUs Available: ", len(tf.config.experimental.list_physical_devices('GPU')))
print("Num CPUs Available: ", len(tf.config.experimental.list_physical_devices('CPU')))

parser = argparse.ArgumentParser()
#parser.add_argument('data', help='Path to data npz files')
parser.add_argument('--trainid', default=None, help='Save model weights to (.npz file)')
parser.add_argument('--model', default=None, help='Resume from previous model')
parser.add_argument('--root_dir', help='Directory of files containing positive and negative files')
parser.add_argument('--block_dir', help='Directory of files containing scan transcriptime files')
parser.add_argument('--polyAfile', help='polyA file from RAN-Seq conataining position and polyA read counts')
parser.add_argument('--round',help='Round of training')
parser.add_argument('--nfolds', default=10, type=int, help='Seperate the data into how many folds')
parser.add_argument('--combination', default='SC', type=str, help='combination of input data')
parser.add_argument('--learning_rate', default=1e-4, type=float, help='learning rate')
parser.add_argument('--epochs', default=100, type=int, help='number of epochs')
opts = parser.parse_args()
#Data = opts.data
trainid=opts.trainid
Path= opts.model
NUM_FOLDS = opts.nfolds
ROOT_DIR  = opts.root_dir
BLOCK_DIR  = opts.block_dir
ROUNDNAME  = opts.round
polyA_file = opts.polyAfile
combination = opts.combination
epochs =  opts.epochs
learning_rate = opts.learning_rate

print('trainid is '+trainid) 
train_data,train_labels = prep_data(ROOT_DIR,BLOCK_DIR,polyA_file,ROUNDNAME,NUM_FOLDS,'train')
valid_data,valid_labels = prep_data(ROOT_DIR,BLOCK_DIR,polyA_file,ROUNDNAME,NUM_FOLDS,'valid')
training_generator =  DataGenerator(train_data,train_labels)
validation_generator = DataGenerator(valid_data,valid_labels)

checkpoint_path = "Model/"+trainid+"-{epoch:04d}.ckpt"
checkpoint_dir = os.path.dirname(checkpoint_path)
# Create a callback that saves the model's weights
cp_callback = ModelCheckpoint(filepath=checkpoint_path,save_weights_only=True,verbose=1,period=1)


model = PolyA_CNN(combination)
#if Path != None:
if os.path.exists(Path+'.index'):
	print ('loading model '+Path)
	model.load_weights(Path) ####load previous model

log_dir = "TensorBoard/CNN/" + trainid + "_" + datetime.now().strftime("%Y%m%d-%H%M%S")
tensorboard_cbk = TensorBoard(log_dir=log_dir)
#tensorboard_cbk = None

lr_schedule = schedules.ExponentialDecay(learning_rate,decay_steps=5000,decay_rate=0.96)
model.compile(loss='binary_crossentropy', optimizer= SGD(momentum = 0.98, learning_rate = lr_schedule), metrics=[binary_accuracy])
#model.compile(loss='binary_crossentropy', optimizer= Adam(learning_rate = learning_rate), metrics=[binary_accuracy])

#plot_model(model, to_file=combination+'model_plot.png', show_shapes=True, show_layer_names=True)
#print(model.summary())

#model.fit({"seq_input": train_data1, "cov_input": train_data2,"polyA_input":train_data3}, train_labels,batch_size=32,epochs=epochs,validation_data=({"seq_input": valid_data1, "cov_input": valid_data2,"polyA_input":valid_data3}, valid_labels),callbacks=[tensorboard_cbk,cp_callback])
#model.fit(train_data,train_labels,batch_size=32,epochs=epochs,validation_data=(valid_data,valid_labels),callbacks=[tensorboard_cbk,cp_callback])
model.fit(training_generator,epochs=epochs,validation_data=validation_generator,
		callbacks=[tensorboard_cbk,cp_callback])
