#!/usr/bin/python

"""
Sample a traning set for a case by drawing from all other images using stratified random sampling.

arg1: directory with case-folders containing feature files
arg2: directory containing segmentations
arg3: directory containing brain masks
arg4: target directory
arg5: file containing a struct identifying the features to sample
arg6: number of samples to draw
arg7+: indices of all cases from which to draw the training sample
"""

import os
import sys
import imp
import numpy
import pickle
import itertools

from medpy.io import load
from medpy.features.utilities import append, join

# main settings
min_no_of_samples_per_class_and_case = 4

# debug settings
verboose = True
debug = True
override = False # activate override (will signal a warning)

def main():
	# catch arguments
	src_dir = sys.argv[1]
	seg_dir = sys.argv[2]
	msk_dir = sys.argv[3]
	trg_dir = sys.argv[4]
	feature_cnf_file = sys.argv[5]
	total_no_of_samples = int(sys.argv[6])
	training_set_cases = sys.argv[7:]

	# load features to use and create proper names from them
	features_to_use = load_feature_names(feature_cnf_file)

	# warn if target sample set already exists
	if os.path.isfile('{}/trainingset.features.npy'.format(trg_dir)):
		if override:
			print 'WARNING: The target file {}/trainingset.features.npy already exists and will be replaced by a new sample.'.format(trg_dir)
		else:
			print 'WARNING: The target file {}/trainingset.features.npy already exists. Skipping.'.format(trg_dir)
			sys.exit(0)

	if verboose: print 'Preparing leave-out training set'
	# initialize collection variables
	training_set_classes_selections = dict.fromkeys(training_set_cases)
	
	# use stratified random sampling to select a number of sample for each case
	for case in training_set_cases:
		if verboose: print 'Stratified random sampling of case {}'.format(case)
		# determine number of samples to draw from this case
		samples_to_draw = int(total_no_of_samples / len(training_set_cases))
		if debug: print 'samples_to_draw', samples_to_draw
		# load class memberships of case as binary and integer array
		mask = load(os.path.join(msk_dir, '{}.nii.gz'.format(case)))[0].astype(numpy.bool)
		truth = load(os.path.join(seg_dir, '{}.nii.gz'.format(case)))[0].astype(numpy.int8)
		class_vector = truth[mask]
		n_class_vector = len(class_vector)
		classes = numpy.unique(class_vector)
		n_classes = len(classes)
		if debug: print 'n_classes', n_classes
		# determine class ratios i.e. how many samples of each class to draw from this case
		n_samples_class = [numpy.count_nonzero(c == class_vector) for c in classes]
		classes_ratios = [nsc / float(n_class_vector) for nsc in n_samples_class]
		classes_samples_to_draw = [int(samples_to_draw * cr) for cr in classes_ratios]
		if debug:
		    for c, cr, cstd in zip(classes, classes_ratios, classes_samples_to_draw):
		        print 'drawing {} samples (equals {} of 1) for class {}'.format(cstd, cr, c)
		# check for exceptions
		for c, cstd, nsc in zip(classes, classes_samples_to_draw, n_samples_class):
		    if cstd < min_no_of_samples_per_class_and_case:
		        raise Exception('Current setting would lead to a drawing of only {} samples of class {} for case {}!'.format(cstd, c, case))
		    if cstd > nsc:
		        raise Exception('Current settings would require to draw {} samples of class {}, but only {} present for case {}!'.format(cstd, c, nsc, case))
		# get sample indices and split into class-wise indices
		samples_indices = numpy.arange(n_class_vector)
		classes_samples_indices = [samples_indices[class_vector == c] for c in classes]
		if debug:
		    for c, csi in zip(classes, classes_samples_indices):
		        print 'class{}_samples_indices.shape: {}'.format(c, csi.shape)
		# randomly draw the required number of sample indices
		for csi in classes_samples_indices:
		    numpy.random.shuffle(csi) # in place
		classes_sample_selection = [csi[:cstd] for csi, cstd in zip(classes_samples_indices, classes_samples_to_draw)]
		if debug:
		    for c, css in zip(classes, classes_sample_selection):
		        print 'class{}_samples_selection.shape: {}'.format(c, css.shape)
		# add to collection
		training_set_classes_selections[case] = dict(zip(classes, classes_sample_selection))
		
	# load the features of each case, draw the samples from them and append them to a training set
	drawn_samples = dict()
	
	for case in training_set_cases:
		if verboose: print 'Sampling features of case {}'.format(case)
		
		# loading and sampling features piece-wise to avoid excessive memory requirements
		drawn_samples_case = dict()
		for feature_name in features_to_use:
			_file = os.path.join(src_dir, case, '{}.npy'.format(feature_name))
			if not os.path.isfile(_file):
				raise Exception('The feature "{}" for case {} could not be found in folder "{}". Breaking.'.format(feature_name, case, os.path.join(src_dir, case)))
			with open(_file, 'r') as f:
				feature_vector = numpy.load(f)
				tscs = training_set_classes_selections[case]
				for cla, sel in tscs.iteritems():
				    if not cla in drawn_samples_case:
				        drawn_samples_case[cla] = []
				    drawn_samples_case[cla].append(feature_vector[sel])
				
		# join and append feature vector from this case
		for cla, samples in drawn_samples_case.iteritems():
		    if not cla in drawn_samples:
		        drawn_samples[cla] = []
		    drawn_samples[cla].append(join(*samples)) # vertical join of different features
		
	# prepare training set as numpy array and the class memberships
	samples = [append(*csamples) for csamples in drawn_samples.itervalues()] # append samples belonging to the same class
	samples_length = [len(x) for x in samples]
	samples_class_memberships = numpy.zeros(sum(samples_length), dtype=numpy.int8)
	i = 0
	for c, sl in zip(drawn_samples.keys(), samples_length):
	    samples_class_memberships[i:i+sl] = c
	    i += sl
	samples_feature_vector = append(*samples)
	
	if debug: print 'n_classes', len(drawn_samples)
	if debug: print 'samples_feature_vector shape', samples_feature_vector.shape
	if debug: print 'class_memberships shape', samples_class_memberships.shape
	if debug: print 'class_memberships dytpe', samples_class_memberships.dtype
	if debug: print 'class_memberships unique', numpy.unique(samples_class_memberships)
	
	# save feature vector, feature names and class membership vector as leave-one-out training set
	if verboose: print 'Saving training data set'
	with open('{}/trainingset.features.npy'.format(trg_dir), 'wb') as f:
		numpy.save(f, samples_feature_vector)
	with open('{}/trainingset.classes.npy'.format(trg_dir), 'wb') as f:
		numpy.save(f, samples_class_memberships)
	with open('{}/trainingset.fnames.npy'.format(trg_dir), 'wb') as f:
		numpy.save(f, features_to_use)
	with open('{}/trainingset.classesselections.pkl'.format(trg_dir), 'wb') as f:
		pickle.dump(training_set_classes_selections, f)
		
	if verboose: print
			
	if verboose: print 'Done.'

def feature_struct_entry_to_name(fstruct):
	seq, fcall, fargs, _ = fstruct
	return 'feature.{}.{}.{}'.format(seq, fcall.func_name, '_'.join(['arg{}'.format(i) for i in fargs]))
	
def load_feature_struct(f):
	"Load the feature struct from a feature config file."
	d, m = os.path.split(os.path.splitext(f)[0])
	f, filename, desc = imp.find_module(m, [d])
	return imp.load_module(m, f, filename, desc).features_to_extract

def load_feature_names(f):
	"Load the feature names from a feature config file."
	fs = load_feature_struct(f)
	return [feature_struct_entry_to_name(e) for e in fs]

if __name__ == "__main__":
	main()




