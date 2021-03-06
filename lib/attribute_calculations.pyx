import numpy as np
from scipy import stats as spstats
from ctypes import *


def analyze_srgb_image(input_image, watershed_image, segment_id=False):
    '''
    Cacluate the attributes for each segment given in watershed_image
    using the raw pixel values in input image. Attributes calculated for
    srgb type images.
    '''
    feature_matrix = []

    cdef int num_ws
    cdef int x_dim, y_dim, num_bands
    cdef double features[16]
    cdef int ws, b
    # cdef int histogram_i
    # cdef int histogram_e
   
    # If no segment id is provided, analyze the features for every watershed
    # in the input image. If a segment id is provided, just analyze the features
    # for that one segment.
    # We have to add +1 to num_ws because if the maximum value in watershed_image
    # is 500, then there are 501 total watersheds Sum(0,1,...,499,500) = 500+1
    if segment_id == False:
        num_ws = int(np.amax(watershed_image) + 1)
    else:
        num_ws = 1

    x_dim, y_dim, num_bands = np.shape(input_image)

   #### Need to convert images to dtype c_int
    # input_image = np.ndarray.astype(input_image, c_int)
    # watershed_image = np.ndarray.astype(watershed_image, c_int)
    if segment_id is not False:
        internal, external = selective_pixel_sort(input_image, watershed_image,
                                    x_dim, y_dim, num_bands, segment_id)
    else:
        internal, external = pixel_sort(input_image, watershed_image,
                                        x_dim, y_dim,
                                        num_ws, num_bands)

    for ws in range(num_ws):

        # Check for empty watershed labels
        if internal[0][ws] == []:
            features = [0 for _ in range(16)]
            feature_matrix.append(features)
            continue

        # Average Pixel Intensity of each band
        for b in range(3):
            features[b] = np.average(internal[b][ws])
            if features[b] < 1:
                features[b] = 1

        # Standard Deviation of each band
        features[3] = np.std(internal[0][ws])
        features[4] = np.std(internal[1][ws])
        features[5] = np.std(internal[2][ws])

        # See Miao et al for band ratios
        # Band Ratio 1
        features[6] = ((features[2] - features[0]) /
                       (features[2] + features[0]))
        # Band Ratio 2
        features[7] = ((features[2] - features[1]) /
                       (features[2] + features[1]))
        # Band Ratio 3
        # Prevent division by 0
        if (2 * features[2] - features[1] - features[0]) < 1:
            features[8] = 0
        else:
            features[8] = ((features[1] - features[0]) /
                           (2 * features[2] - features[1] - features[0]))

        # Size of Superpixel
        features[9] = len(internal[0][ws])

        # Entropy
        histogram_i = np.bincount(internal[1][ws])
        features[10] = spstats.entropy(histogram_i,base=2)

        ## Neighborhood Values
        # N. Average Intensity
        features[11] = np.average(external[1][ws])
        # N. Standard Deviation
        features[12] = np.std(external[1][ws])
        # N. Maximum Single Value
        features[13] = np.amax(external[1][ws])
        # N. Entropy
        histogram_e = np.bincount(external[1][ws])
        features[14] = spstats.entropy(histogram_e,base=2)

        # Date of image acquisition
        features[15] = 0

        feature_matrix.append(features)

    return feature_matrix


def analyze_ms_image(input_image, watershed_image, segment_id=False):
    '''
    Cacluate the attributes for each segment given in watershed_image
    using the raw pixel values in input image. Attributes calculated for
    multispectral type WorldView 2 images.
    '''
    feature_matrix = []

    cdef int num_ws
    cdef int x_dim, y_dim, num_bands
    cdef double features[18]
    cdef int ws, b
    # cdef int histogram_i
    # cdef int histogram_e
   
    # If no segment id is provided, analyze the features for every watershed
    # in the input image. If a segment id is provided, just analyze the features
    # for that one segment.
    # We have to add +1 to num_ws because if the maximum value in watershed_image
    # is 500, then there are 501 total watersheds Sum(0,1,...,499,500) = 500+1
    if segment_id == False:
        num_ws = int(np.amax(watershed_image) + 1)
    else:
        num_ws = 1

    x_dim, y_dim, num_bands = np.shape(input_image)

   #### Need to convert images to dtype c_int (done elsewhere)
    # input_image = np.ndarray.astype(input_image, c_int)
    # watershed_image = np.ndarray.astype(watershed_image, c_int)
    if segment_id is not False:
        internal, external = selective_pixel_sort(input_image, watershed_image,
                                    x_dim, y_dim, num_bands, segment_id)
    else:
        internal, external = pixel_sort(input_image, watershed_image,
                                        x_dim, y_dim,
                                        num_ws, num_bands)

    for ws in range(num_ws):
        # Check for empty watershed labels
        if internal[0][ws] == []:
            features = [0 for _ in range(18)]
            feature_matrix.append(features)
            continue
        # Average Pixel Intensity of each band
        for b in range(8):
            features[b] = np.average(internal[b][ws])
            if features[b] < 1:
                features[b] = 1

        # Important band ratios
        features[8] = (features[0] / features[2])
        features[9] = (features[1] / features[6])
        features[10] = (features[4] / features[6])
        features[11] = (features[3] / features[5])
        features[12] = (features[3] / features[6])
        features[13] = (features[3] / features[7])
        features[14] = (features[4] / features[6])

        # N. Average Intensity 
        features[15] = np.average(external[4][ws])

        # b1-b7 / b1+b7
        features[16] = ((features[0] - features[6]) / (features[0] + features[6]))
        # b3-b5 / b3+b5
        features[17] = ((features[2] - features[4]) / (features[2] + features[4]))

        feature_matrix.append(features)

    return feature_matrix


def analyze_pan_image(input_image, watershed_image, date, segment_id=False):
    '''
    Cacluate the attributes for each segment given in watershed_image
    using the raw pixel values in input image. Attributes calculated for
    srgb type images.
    '''
    feature_matrix = []

    cdef int num_ws
    cdef int x_dim, y_dim, num_bands
    cdef double features[12]
    cdef int ws, b
    # cdef int histogram_i
    # cdef int histogram_e
   
    # If no segment id is provided, analyze the features for every watershed
    # in the input image. If a segment id is provided, just analyze the features
    # for that one segment.
    # We have to add +1 to num_ws because if the maximum value in watershed_image
    # is 500, then there are 501 total watersheds Sum(0,1,...,499,500) = 500+1
    if segment_id == False:
        num_ws = int(np.amax(watershed_image) + 1)
    else:
        num_ws = 1

    x_dim, y_dim, num_bands = np.shape(input_image)

   #### Need to convert images to dtype c_int
    # input_image = np.ndarray.astype(input_image, c_int)
    # watershed_image = np.ndarray.astype(watershed_image, c_int)
    if segment_id is not False:
        internal, external = selective_pixel_sort(input_image, watershed_image,
                                    x_dim, y_dim, num_bands, segment_id)
    else:
        internal, external = pixel_sort(input_image, watershed_image,
                                        x_dim, y_dim,
                                        num_ws, num_bands)

    for ws in range(num_ws):
        
        # Check for empty watershed labels
        if internal[0][ws] == []:
            features = [0 for _ in range(12)]
            feature_matrix.append(features)
            continue

        # Average Pixel Intensity
        features[0] = np.average(internal[0][ws])
        if features[0] < 1:
            features[0] = 1

        # Median Pixel Value
        features[1] = np.median(internal[0][ws])
        # Segment Minimum
        features[2] = np.amin(internal[0][ws])
        # Segment Maximum
        features[3] = np.amax(internal[0][ws])
        # Standard Deviation
        features[4] = np.std(internal[0][ws])
        # Size
        features[5] = len(internal[0][ws])

        # Entropy
        histogram_i = np.bincount(internal[0][ws])
        features[6] = spstats.entropy(histogram_i,base=2)

        ## Neighborhood Values
        # N. Average Intensity
        features[7] = np.average(external[0][ws])
        # N. Standard Deviation
        features[8] = np.std(external[0][ws])
        # N. Maximum Single Value
        features[9] = np.amax(external[0][ws])
        # N. Entropy
        histogram_e = np.bincount(external[0][ws])
        features[10] = spstats.entropy(histogram_e,base=2)

        # Date of image acquisition
        features[11] = int(date)

        feature_matrix.append(features)

    return feature_matrix


def selective_pixel_sort(int[:,:,:] intensity_image_view,
                         int[:,:] label_image_view,
                         int x_dim, int y_dim, 
                         int num_bands, int label):
    
    cdef int y,x,i,w,b
    cdef int window[4]
    cdef int sn

    # Output variables. 
    #  Future work: Improve data structure here to something more efficient.
    internal = [[[]] for _ in range(num_bands)]
    external = [[[]] for _ in range(num_bands)]

    # Moving window that defines the neighboring region for each pixel
    window = [-4, -3, 3, 4]

    for y in range(y_dim):
        for x in range(x_dim):
            # Set the current segment number
            sn = label_image_view[x,y]

            # Select only the ws with the correct label
            if sn != label:
                continue

            # Assign the internal pixel
            for b in range(num_bands):
                internal[b][0].append(intensity_image_view[x,y][b])

            # Determine the external values within the window
            for w in range(4):
                i = window[w]
                # Determine the external values in the x-axis
                # Check for edge conditions
                if (x+i < 0) or (x+i >= x_dim):
                    continue
                if label_image_view[x+i,y] != sn:
                    for b in range(num_bands):
                        external[b][0].append(intensity_image_view[x+i,y][b])
                # Determine the external values in the y-axis
                # Check for edge conditions
                if (y+i < 0) or (y+i >= y_dim):
                    continue
                if label_image_view[x,y+i] != sn:
                    for b in range(num_bands):
                        external[b][0].append(intensity_image_view[x,y+i][b])

    return internal, external


def pixel_sort(int[:,:,:] intensity_image_view,
               int[:,:] label_image_view,
               int x_dim, int y_dim, int num_ws, int num_bands):
    '''
    Given an intensity image and label image of the same dimension, sort
    pixels into a list of internal and external intensity pixels for every 
    label in the label image. 
    Returns:
        Internal: Array of length (number of labels), each element is a list
            of intensity values for that label number.
        External: Array of length (number of labels), each element is a list
            of intensity values that are adjacent to that label number.
    '''
    cdef int y,x,i,w
    cdef int window[4]
    cdef int sn

    # Output variables. 
    #  Future work: Improve data structure here to something more efficient.
    internal = [[[] for _ in range(num_ws)] for _ in range(num_bands)]
    external = [[[] for _ in range(num_ws)] for _ in range(num_bands)]

    # internal = cvarray(shape=(num_ws,1), itemsize=sizeof(int), format="i")
    # cdef int [:] internal_view = internal
    
    # external = cvarray(shape=(num_ws,1), itemsize=sizeof(int), format="i")
    # cdef int [:] external_view = external

    # Moving window that defines the neighboring region for each pixel
    window = [-4, -3, 3, 4]

    for y in range(y_dim):
        for x in range(x_dim):
            # Set the current segment number
            sn = label_image_view[x,y]
            # Assign the internal pixel
            for b in range(num_bands):
                internal[b][sn].append(intensity_image_view[x,y][b])

            # Determine the external values within the window
            for w in range(4):
                i = window[w]
                # Determine the external values in the x-axis
                # Check for edge conditions
                if (x+i < 0) or (x+i >= x_dim):
                    continue
                if label_image_view[x+i,y] != sn:
                    for b in range(num_bands):
                        external[b][sn].append(intensity_image_view[x+i,y][b])

                # Determine the external values in the y-axis
                # Check for edge conditions
                if (y+i < 0) or (y+i >= y_dim):
                    continue
                if label_image_view[x,y+i] != sn:
                    for b in range(num_bands):
                        external[b][sn].append(intensity_image_view[x,y+i][b])

    return internal, external
