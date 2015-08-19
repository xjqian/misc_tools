#!/bin/sh

if  [ $# -ne 3 ]; then
    echo "Usage: shell script to average a chunk of slices in any dimension"
    echo ""
    echo "      "`basename $0`" <image> <number of slices> <dimension>"
    echo ""
    echo "e.g., "`basename $0`" T1w 16 x"
    echo ""
    echo "N.B. <image> must be a NIFTI filename without extension"
    exit -1
fi

# initialize parameters
img=$1
avg=$2
dir=$3

dim1=`fslval ${img} dim1`
dim2=`fslval ${img} dim2`
dim3=`fslval ${img} dim3`

case ${dir} in
x) oldpixdim=`fslval ${img} pixdim1`
   let "nseg = ${dim1} / ${avg}"
   ;;
y) oldpixdim=`fslval ${img} pixdim2`
   let "nseg = ${dim2} / ${avg}"
   ;;
z) oldpixdim=`fslval ${img} pixdim3`
   let "nseg = ${dim3} / ${avg}"
   ;;
*) echo dimension other than x, y, z is invalid
   exit -1
   ;;
esac

newpixdim=`echo "\${oldpixdim} * \${avg}" | bc`

# prepare initial dummy output file
imgavg=${img}_avg${avg}${dir}
case ${dir} in
x) fslroi ${img} ${imgavg} 0 1 0 -1 0 -1
   ;;
y) fslroi ${img} ${imgavg} 0 -1 0 1 0 -1 
   ;;
z) fslroi ${img} ${imgavg} 0 -1 0 -1 0 1
   ;;
*) echo dimension other than x, y, z is invalid
   exit -1
   ;;
esac

echo average every ${avg} slices in ${dir} dimension
for ((i=1; i<=${nseg}; i++))
do
    let "k = (${i} - 1) * ${avg}"
    case ${dir} in
    x)   fslroi ${img} ${img}_${i} ${k} ${avg} 0 -1 0 -1
         fslmaths ${img}_${i} -Xmean ${img}_${i}_Xmean
         fslmerge -x ${imgavg} ${imgavg} ${img}_${i}_Xmean
         ;;
    y)   fslroi ${img} ${img}_${i} 0 -1 ${k} ${avg} 0 -1
         fslmaths ${img}_${i} -Ymean ${img}_${i}_Ymean
         fslmerge -y ${imgavg} ${imgavg} ${img}_${i}_Ymean
         ;;
    z)   fslroi ${img} ${img}_${i} 0 -1 0 -1 ${k} ${avg}
         fslmaths ${img}_${i} -Zmean ${img}_${i}_Zmean
         fslmerge -z ${imgavg} ${imgavg} ${img}_${i}_Zmean
         ;;
    *)   echo dimension other than x, y, z is invalid
         exit -1
         ;;
    esac
done

# remove the first dummy slice and adapt averaged pixdim in the header
case ${dir} in
x)   fslroi ${imgavg} ${imgavg} 1 ${nseg} 0 -1 0 -1
     fslmodhd ${imgavg} pixdim1 ${newpixdim}
     ;;
y)   fslroi ${imgavg} ${imgavg} 0 -1 1 ${nseg} 0 -1
     fslmodhd ${imgavg} pixdim2 ${newpixdim}
     ;;
z)   fslroi ${imgavg} ${imgavg} 0 -1 0 -1 1 ${nseg}
     fslmodhd ${imgavg} pixdim3 ${newpixdim}
     ;;
*)   echo dimension other than x, y, z is invalid
     exit -1
     ;;
esac
