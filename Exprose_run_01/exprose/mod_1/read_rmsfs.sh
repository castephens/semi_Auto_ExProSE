#!bin/bash

#Author: Christina Stephens
#Date: 01/23/2019

rmsfs=$1
pdb=$2

res_len=`wc -l $rmsfs | awk '{print $1}'`

res=`grep ATOM $pdb | head -1 | awk '{print $6}'`

grep ATOM $pdb | grep CA | awk '{print $6}' > protein_resid.txt

check1=0
check2=0
check3=0
check4=0
check5=0
check6=0
check7=0
check8=0

for i in $(seq 1 ${res_len}); do
	
	value=`awk 'NR=='${i}'' ${rmsfs}`

  	if (( $(echo "$value < 0.4" | bc -l) )); then
		if [ $check1 == 0 ]; then
			group1="color blue, resid $res"
			check1=1
		else 
			group1="${group1} or resid ${res}"
		fi

	elif (( $(echo "0.4 <= $value && $value < 0.5" | bc -l) )); then
		if [ $check2 == 0 ]; then
                        group2="color marine, resid $res"
                        check2=1
                else
                        group2="${group2} or resid ${res}"
                fi

	elif (( $(echo "0.5 <= $value && $value < 0.6" | bc -l) )); then
                if [ $check3 == 0 ]; then
                        group3="color lightblue, resid $res"
                        check3=1
                else
                        group3="${group3} or resid ${res}"
                fi

	elif (( $(echo "0.6 <= $value && $value < 0.7" | bc -l) )); then
                if [ $check4 == 0 ]; then
                        group4="color violetpurple, resid $res"
                        check4=1
                else
                        group4="${group4} or resid ${res}"
                fi

	elif (( $(echo "0.7 <= $value && $value < 0.8" | bc -l) )); then
                if [ $check5 == 0 ]; then
                        group5="color violet, resid $res"
                        check5=1
                else
                        group5="${group5} or resid ${res}"
                fi

	elif (( $(echo "0.8 <= $value && $value < 0.9" | bc -l) )); then
                if [ $check6 == 0 ]; then
                        group6="color pink, resid $res"
                        check6=1
                else
                        group6="${group6} or resid ${res}"
                fi	
	
	elif (( $(echo "0.9 <= $value && $value < 1" | bc -l) )); then
                if [ $check7 == 0 ]; then
                        group7="color raspberry, resid $res"
                        check7=1
                else
                        group7="${group7} or resid ${res}"
                fi

	elif (( $(echo "1 <= $value" | bc -l) )); then
                if [ $check8 == 0 ]; then
                        group8="color red, resid $res"
                        check8=1
                else
                        group8="${group8} or resid ${res}"
                fi
	fi

	j=`echo "${i} + 1" | bc -l`
	res=`awk 'NR=='${j}'{print}' protein_resid.txt`
done

wkdir=`pwd`
file='color_by_rmsfs.pml'
echo "load ${wkdir}/${pdb}" > $file 
echo "select p, all" >> $file
echo "color white, p" >> $file

echo "select p_loop, resid 17-23" >> $file
echo "select switch_1, resid 39-45" >> $file
echo "select G3__DxxG, resid 65-68" >> $file
echo "select switch_2, resid 67-75" >> $file
echo "select G4, resid 122-125" >> $file
echo "select G5__SAK, resid 150-152" >> $file

echo "${group1}" >> $file
echo "${group2}" >> $file
echo "${group3}" >> $file
echo "${group4}" >> $file
echo "${group5}" >> $file
echo "${group6}" >> $file
echo "${group7}" >> $file
echo "${group8}" >> $file


