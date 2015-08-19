#! /bin/sh

# Author: Junqian (Gordon) Xu <jxu@umn.edu>
#
# ToDo: add optional mask

if  [ $# -ne 1 ]; then
    echo "Usage: shell script to calculate flip angle map from actual flip angle imaging (AFI) "
    echo ""
    echo "       afi.sh <input>"
    echo ""
    echo "e.g.,  afi.sh image"
    echo " N.B.  image is assumed to have 2 volumes"
    echo ""
    echo "output: image_fa"
    echo ""
    exit -1
fi

img=$1

# need to know from acquisition protocol
# target flip angle = 50 deg
TR1=20  # (ms)
TR2=120 # (ms)

n=6 # TR2/TR1

fslroi $img AFI_TR1 0 1
fslroi $img AFI_TR2 1 1

# Actual flip angle imaging (AFI)
# Yarnykh, Magnetic Resonance in Medicine 57:192–200 (2007) Equation [6]

fslmaths AFI_TR2 -div AFI_TR1 AFI_ratio -odt float
fslmaths AFI_ratio -mul $n -sub 1 AFI_numerator -odt float
fslmaths AFI_ratio -mul 0 -add $n -sub AFI_ratio AFI_denominator -odt float
fslmaths AFI_numerator -div AFI_denominator AFI_temp -odt float

# AFNI
if [ -f AFI_fa.nii.gz ] ; then
   imrm AFI_fa
fi
/usr/lib/afni/bin/3dcalc -a AFI_temp.nii.gz -expr 'acos(a)' -prefix AFI_fa.nii.gz -datum float

fslmaths AFI_fa -mul 180 -div 3.1415926 AFI_fa -odt float


