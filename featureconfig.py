####
# Configuration file: Denotes the features to extract
####

from medpy.features.intensity import intensities, centerdistance, centerdistance_xdminus1, local_mean_gauss, local_histogram

MRI = [
	('MRI', intensities, [], False),
	('MRI', local_mean_gauss, [3], True),
	('MRI', local_mean_gauss, [5], True),
	('MRI', local_mean_gauss, [7], True),
	('MRI', local_histogram, [11, 'image', (0, 100), 5, None, None, 'ignore', 0], False), #11 bins, 5*2=10mm region
	('MRI', local_histogram, [11, 'image', (0, 100), 10, None, None, 'ignore', 0], False), #11 bins, 10*2=20mm region
	('MRI', local_histogram, [11, 'image', (0, 100), 15, None, None, 'ignore', 0], False), #11 bins, 15*2=30mm region
	('MRI', centerdistance_xdminus1, [0], True),
	('MRI', centerdistance_xdminus1, [1], True),
	('MRI', centerdistance_xdminus1, [2], True)
]

APROBL0 = [
	('aprobl0', intensities, [], False),
	('aprobl0', local_mean_gauss, [5], True),
	('aprobl0', local_mean_gauss, [10], True),
	('aprobl0', local_mean_gauss, [20], True)
]

APROBL1 = [
	('aprobl1', intensities, [], False),
	('aprobl1', local_mean_gauss, [5], True),
	('aprobl1', local_mean_gauss, [10], True),
	('aprobl1', local_mean_gauss, [20], True)
]

APROBL2 = [
	('aprobl2', intensities, [], False),
	('aprobl2', local_mean_gauss, [5], True),
	('aprobl2', local_mean_gauss, [10], True),
	('aprobl2', local_mean_gauss, [20], True)
]

APROBL3 = [
	('aprobl3', intensities, [], False),
	('aprobl3', local_mean_gauss, [5], True),
	('aprobl3', local_mean_gauss, [10], True),
	('aprobl3', local_mean_gauss, [20], True)
]

APROBL4 = [
	('aprobl4', intensities, [], False),
	('aprobl4', local_mean_gauss, [3], True),
	('aprobl4', local_mean_gauss, [10], True),
	('aprobl4', local_mean_gauss, [20], True)
]

APROBL5 = [
	('aprobl5', intensities, [], False),
	('aprobl5', local_mean_gauss, [5], True),
	('aprobl5', local_mean_gauss, [10], True),
	('aprobl5', local_mean_gauss, [20], True)
]

APROBL6 = [
	('aprobl6', intensities, [], False),
	('aprobl6', local_mean_gauss, [5], True),
	('aprobl6', local_mean_gauss, [10], True),
	('aprobl6', local_mean_gauss, [20], True)
]

APROBL7 = [
	('aprobl7', intensities, [], False),
	('aprobl7', local_mean_gauss, [5], True),
	('aprobl7', local_mean_gauss, [10], True),
	('aprobl7', local_mean_gauss, [20], True)
]

features_to_extract = MRI + APROBL1 + APROBL2 + APROBL3 + APROBL4 + APROBL5 + APROBL6 + APROBL7


