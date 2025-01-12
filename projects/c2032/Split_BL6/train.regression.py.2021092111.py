from RegressionModel import *
import os, sys, copy, getopt, re, argparse
import random
from datetime import datetime
import pandas as pd 
import numpy as np
from tensorflow.keras.callbacks import TensorBoard
from tensorflow.keras.callbacks import ModelCheckpoint
from prep_data_regression import prep_data,DataGenerator

print("Num GPUs Available: ", len(tf.config.experimental.list_physical_devices('GPU')))
print("Num CPUs Available: ", len(tf.config.experimental.list_physical_devices('CPU')))

parser = argparse.ArgumentParser()
parser.add_argument('--trainid', default=None, help='Save model weights to (.npz file)')
parser.add_argument('--model', default=None, help='Resume from previous model')
parser.add_argument('--file_path', help='Directory of files containing positive and negative files')
parser.add_argument('--nfolds', default=5, type=int, help='Seperate the data into how many folds')
parser.add_argument('--learning_rate', default=1e-4, type=float, help='learning rate')
parser.add_argument('--epochs', default=100, type=int, help='number of epochs')
parser.add_argument('--shift', default=0, type=int, help='shift augmentation')
args = parser.parse_args()
trainid=args.trainid
Path= args.model
NUM_FOLDS = args.nfolds
FILE_PATH = args.file_path
epochs =  args.epochs
learning_rate = args.learning_rate
shift = args.shift
length=2001

print('trainid is '+trainid) 
train_data,train_labels,valid_data,valid_labels = prep_data(FILE_PATH,NUM_FOLDS)
train_data = np.log((train_data+1)/12.61)
train_labels = np.log(train_labels/17.25)
valid_data  = np.log((valid_data+1)/12.61)
valid_labels = np.log(valid_labels/17.25)
training_generator =  DataGenerator(train_data,train_labels,shift)
validation_generator = DataGenerator(valid_data,valid_labels,0)

checkpoint_path = "Model/"+trainid+"-{epoch:04d}.ckpt"
checkpoint_dir = os.path.dirname(checkpoint_path)
# Create a callback that saves the model's weights
cp_callback = ModelCheckpoint(filepath=checkpoint_path,save_weights_only=True,verbose=1,period=1)


model = Regression_CNN(length)

log_dir = "TensorBoard/Regression/" + trainid + "_" + datetime.now().strftime("%Y%m%d-%H%M%S")
tensorboard_cbk = TensorBoard(log_dir=log_dir)

lr_schedule = schedules.ExponentialDecay(learning_rate,decay_steps=5000,decay_rate=0.96)
#model.compile(loss='mean_squared_logarithmic_error', optimizer= SGD(momentum = 0.98, learning_rate = lr_schedule), metrics=['mse'])
model.compile(loss='mean_squared_error', optimizer= SGD(momentum = 0.98, learning_rate = lr_schedule), metrics=['mse'])

#plot_model(model, to_file=combination+'model_plot.png', show_shapes=True, show_layer_names=True)
#print(model.summary())

model.fit(training_generator,epochs=epochs,validation_data=validation_generator,
		callbacks=[tensorboard_cbk,cp_callback])
