#!/usr/bin/python

"""
Evaluate the segmentation created.
arg1: the segmentation result for each case, with a {} in place of the case number
arg2: the ground truth segmentation, with a {} in place of the case number
arg3: the cases mask file, with a {} in place of the case number
arg4+: the cases to evaluate
"""

import sys
import math
import time
from multiprocessing.pool import Pool

import numpy
from scipy.ndimage.measurements import label

from medpy.io import load, header, save
from medpy.metric import dc, hd, assd, precision, recall

# constants
n_jobs = 6
silent = True
labels = [1, 2, 3, 4]

def main():

    # catch parameters
    segmentation_base_string = sys.argv[1]
    ground_truth_base_string = sys.argv[2]
    mask_file_base_string = sys.argv[3]
    cases = sys.argv[4:]

    # evaluate each label of each case and collect the scores
    precisions = []
    recalls = []
    dcs = []
    
    # for each case
    for case in cases:
    
        # load images of the current case
        i_segmentation, _ = load(segmentation_base_string.format(case))
        i_truth, _ = load(ground_truth_base_string.format(case))
        i_mask = load(mask_file_base_string.format(case))[0].astype(numpy.bool)

        # collect images for each label in list and apply mask to segmentation and ground truth (to remove ground truth fg outside of brain mask)
        s = [(i_segmentation == d) & i_mask for d in labels]
        t = [(i_truth == d) & i_mask for d in labels]
        
        # post-processing
        from scipy.ndimage.morphology import binary_fill_holes
        s = [binary_fill_holes(_s) for _s in s]
        #from medpy.filter import largest_connected_component
        s[0] = largest_connected_components(s[0], n = 2)
        s[1] = largest_connected_components(s[1], n = 1)
        s[2] = largest_connected_components(s[2], n = 2)
        s[3] = largest_connected_components(s[3], n = 2)
        #from scipy.ndimage.morphology import binary_dilation
        #s = [binary_dilation(_s, structure=None, iterations=4) for _s in s]
        save(numpy.asarray(s), segmentation_base_string.format(case) + '_tmp.nii.gz')
        
        # compute and append metrics (Pool-processing)
        pool = Pool(n_jobs)
        dcs.append(pool.map(wdc, zip(t, s)))
        precisions.append(pool.map(wprecision, zip(s, t)))
        recalls.append(pool.map(wrecall, zip(s, t)))

    # print case-wise and label-wise results results
    print 'Case\t',
    for label in labels:
        print 'Label {}\t\t\t'.format(label),
    print '\n\t',
    for label in labels:
        print 'DC[0,1]\tprec.\trec.\t',
    print
    for case, _dcs, _prs, _rcs in zip(cases, dcs, precisions, recalls):
        print '{}'.format(case),
        for _dc, _pr, _rc in zip(_dcs, _prs, _rcs):
            print '\t{:>3,.3f}\t{:>3,.3f}\t{:>3,.3f}'.format(_dc, _pr, _rc),
        print
    print

    # print label-wise averages
    for lid, label in enumerate(labels):
        print 'Label {} averages:'.format(label)

        _mdcs = [_dc[lid] for _dc in dcs]
        _mpres = [_prs[lid] for _prs in precisions]
        _mrcs = [_rcs[lid] for _rcs in recalls]
        print '\tDM average\t{} +/- {} (Median: {})'.format(numpy.mean(_mdcs), numpy.std(_mdcs), numpy.median(_mdcs))
        print '\tPrec. average\t{} +/- {} (Median: {})'.format(numpy.mean(_mpres), numpy.std(_mpres), numpy.median(_mpres))
        print '\tRec. average\t{} +/- {} (Median: {})'.format(numpy.mean(_mrcs), numpy.std(_mrcs), numpy.median(_mrcs))
    print
        
    # print overall averages (label independent)
    print 'Overall averages:'
    print 'DM  average\t{} +/- {} (Median: {})'.format(numpy.asarray(dcs).mean(), numpy.asarray(dcs).std(), numpy.median(numpy.asarray(dcs)))
    print 'Prec.  average\t{} +/- {} (Median: {})'.format(numpy.asarray(precisions).mean(), numpy.asarray(precisions).std(), numpy.median(numpy.asarray(precisions)))
    print 'Rec.  average\t{} +/- {} (Median: {})'.format(numpy.asarray(recalls).mean(), numpy.asarray(recalls).std(), numpy.median(numpy.asarray(recalls)))

def wdc(x):
    return dc(*x)
def whd(x):
    try:
        val = hd(*x)
    except RuntimeError:
        val = numpy.inf
    return val
def wprecision(x):
    return precision(*x)
def wrecall(x):
    return recall(*x)
def wassd(x):
    try:
        val = assd(*x)
    except RuntimeError:
        val = numpy.inf
    return val
    
def largest_connected_components(img, n = 1, structure = None):
    r"""
    Select the largest connected binary component in an image.
    
    Treats all zero values in the input image as background and all others as foreground.
    The return value is an binary array of equal dimensions as the input array with TRUE
    values where the largest connected component is situated.
    
    Parameters
    ----------
    img : array_like
        An array containing connected objects. Will be cast to type numpy.bool.
    structure : array_like
        A structuring element that defines the connectivity. Structure must be symmetric.
        If no structuring element is provided, one is automatically generated with a
        squared connectivity equal to one.
    
    Returns
    -------
    binary_image : ndarray
        The supplied binary image with only the largest connected component remaining.
    """   
    labeled_array, num_features = label(img, structure)
    component_sizes = [numpy.count_nonzero(labeled_array == label_idx) for label_idx in range(1, num_features + 1)]
    component_indices_list_by_sizes = numpy.argsort(component_sizes)[::-1] + 1

    out = numpy.zeros(img.shape, numpy.bool)
    
    for i in range(n):
        out[labeled_array == component_indices_list_by_sizes[i]] = True
    return out

if __name__ == "__main__":
    main()
