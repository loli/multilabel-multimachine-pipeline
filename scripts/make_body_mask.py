#!/usr/bin/python

"""
Automatically create a full-body mask for an abdominal MRI image.
<program>.py <in-image> <out-binary-image> [<threshold>]
"""

import sys
import numpy
from medpy.io import load, save, header
from medpy.filter import largest_connected_component, xminus1d
from scipy.ndimage.morphology import binary_opening, binary_closing,\
    binary_erosion, binary_dilation, binary_fill_holes

DEFAULT_THRESHOLD = 50.0

def main():
    i, h = load(sys.argv[1])
    if len(sys.argv) > 3:
        t = float(sys.argv[3])
    else:
        t = DEFAULT_THRESHOLD
        
    # threshold image
    i = i > t
    
    # select only largest connected component
    i = largest_connected_component(i)

    # fill holes along each dimension in 2D
    i = xminus1d(i, binary_fill_holes, 0)
    i = xminus1d(i, binary_fill_holes, 1)
    i = xminus1d(i, binary_fill_holes, 2)

    # select only largest connected component
    i = largest_connected_component(i)
    
    # apply morphological operations
    i = binary_closing(i, structure=None, iterations=3) # 3D
    #i = morphology2d(binary_closing, i, structure=1, iterations=1)

    if 0 == numpy.count_nonzero(i):
	    raise Warning("{}: empty mask resulted".format(sys.argv[1]))

    save(i, sys.argv[2], h, True)

def morphology2d(operation, arr, structure = None, iterations=1, dimension = 2):
	res = numpy.zeros(arr.shape, numpy.bool)
	for sl in range(processed.shape[dimension]):	
		res[:,:,sl] = operation(arr[:,:,sl], structure, iterations)
	return res

if __name__ == "__main__":
	main()


