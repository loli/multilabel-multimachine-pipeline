#!/usr/bin/python

"""
Prints out handy information about the metadata of an NifTi image, especially regarding the transformation to world coordinates.
arg1: the image to check
"""

import sys

import numpy

from medpy.io import load, header

def main():
	i, h = load(sys.argv[1])

	print 'Image:\t{}'.format(sys.argv[1])
	print 'Shape:\t{}'.format(i.shape)
	print 'Spacing:{}'.format(header.get_pixel_spacing(h))
	print 'Offset:\t{}'.format(header.get_offset(h))

	if 0 == h.get_header()['qform_code']:
		method = 'ANALYZE 7.5 (old)'
	if h.get_header()['qform_code'] > 0:
		method = 'Normal (qform)'
	if h.get_header()['sform_code'] > 0:
		method = 'Special space (sform)'

	print
	print 'Orientation and location in space:'
	print 'Type:\t\t{}'.format(method)
	print 'qform_code:\t{}'.format(h.get_header()['qform_code'])
	print 'sform_code:\t{}'.format(h.get_header()['sform_code'])

	print
	print 'qform == sform?\t{} (max diff={})'.format(numpy.all(h.get_qform() == h.get_sform()), numpy.max(numpy.abs(h.get_qform() - h.get_sform())))
	print 'affine = qform?\t{} (max diff={})'.format(numpy.all(h.get_affine() == h.get_qform()), numpy.max(numpy.abs(h.get_affine() - h.get_qform())))
	print 'affine = sform?\t{} (max diff={})'.format(numpy.all(h.get_affine() == h.get_sform()), numpy.max(numpy.abs(h.get_affine() - h.get_sform())))

	print
	print 'qform:'
	print h.get_qform()
	print 'sform:'
	print h.get_sform()
	print 'affine:'
	print h.get_affine()

if __name__ == "__main__":
	main()
