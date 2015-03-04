#!/usr/bin/python

"""
Train a decision forest on a training set.
arg1: the training set file (.features.npy)
arg2: the decision forest target file
arg4: the maximum tree depth (optional)
"""

import sys
import pickle
import numpy

from sklearn.ensemble.forest import ExtraTreesClassifier
from sklearn.ensemble.forest import RandomForestClassifier
#from sklearn.ensemble.forest import MixedForestClassifier

# constants
n_jobs = 6

def main():
	# catch parameters
	training_set_features = sys.argv[1]
	training_set_classes = training_set_features.replace('features', 'classes')
	forest_file = sys.argv[2]
	max_depth = int(sys.argv[3]) if 3 <= len(sys.argv) else 500

        # loading training features
        with open(training_set_features, 'r') as f:
            training_feature_vector = numpy.load(f)
	    if 1 == training_feature_vector.ndim:
		training_feature_vector = numpy.expand_dims(training_feature_vector, -1)
        with open(training_set_classes , 'r') as f:
            training_class_vector = numpy.load(f)
	
        # prepare and train the decision forest
        forest = ExtraTreesClassifier(n_estimators=200,
                            criterion = 'gini',
                            max_features = None, # rdf: auto / et: None
			                #splitter="alternatingnode",
                            min_samples_split = 2,
                            min_samples_leaf = 1,
			                max_depth = max_depth,
                            bootstrap = True,
                            oob_score = False,
                            random_state=None,
                            n_jobs=n_jobs)
        forest.fit(training_feature_vector, training_class_vector)

	# saving the decision forest
	with open(forest_file, 'wb') as f:
		pickle.dump(forest, f)

if __name__ == "__main__":
	main()
