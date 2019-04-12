#!bin/bash 

# Author:  Christina Stephens
# Date:    02/05/2019
# Purpose: High_throughput execution of ExProSE/ProteinEnsembles analysis

#_____________________________

# (1) User input      
#_____________________________

# defaults
param=0
weight=0.3
N=100
num_pockets=1
mod=0
extra=0

#Edit the location to where you copied all the analysis scripts
scripts='semi_auto_ExProSE/'

while getopts ":p:s:n:w:m:e:" opt; do
	case $opt in
    		p)	# paramaterization option
      		if [ $OPTARG == "Y" ] ; then
			echo "" 
			echo "Program will run weight paramaterization for input structures"
      			param=1
      		elif [ $OPTARG == "N" ] ; then
			echo ""
			echo "Will use default weight of 0.3 if no weight inputed"
			param=0
			weight=0.3
      		else
			echo ""
			echo "You entered an invlaid option, please enter [Y] or [N]"
			exit 1
      		fi
      	;;
	
  		s)	# starting structures
            	set -f 		# disable glob
            	IFS=' ' 	# split on space characters
            	pdbs=($OPTARG) 	# use the split+glob operator
		if [ ${#pdbs[@]} == 0 ] ; then
			echo ""
			echo "No input pdbs entered"
			echo "Exiting now."
			exit 1
		fi
	;; 

	        m)      # mod file
		mod=1
        	mod_file=${OPTARG}
	;;


		n)      # number of models
		N=${OPTARG}
	;;

	        w)      # model tolerance
                weight=${OPTARG}
        ;;

		e)      # extra pdbs for PCA
                extra_pdbs=${OPTARG}
		num_extra=`wc -l ${extra_pdbs} | awk '{print $1}'`
		if [ ${num_extra} == 0 ] ; then
			echo ""
                        echo "No input extra pdbs entered"
                        echo "Exiting now."
                        exit 1
               else
                       extra=1
               fi
		
        ;;

	#        e)      # starting structures
        #        set -f          # disable glob
        #        IFS=' '         # split on space characters
        #        x_pdbs=($OPTARG)  # use the split+glob operator
        #        if [ ${#x_pdbs[@]} == 0 ] ; then
        #                echo ""
        #                echo "No input extra pdbs entered"
        #                echo "Exiting now."
        #                exit 1
	#	 else
	#		extra=1
        #        fi
        #;;
			
    esac
done


check_folder=`ls | grep Exprose_run | wc -l`

if [ ${check_folder} == 0 ]; then
        run="01"
else
        r=`echo "${check_folder} + 1" | bc -l`
        run="0${r}"
        while [ -d Exprose_run_${run} ] ; do
                r=`echo "${r} + 1" | bc -l`
                run="0${r}"
        done
fi

mkdir Exprose_run_${run}
cd Exprose_run_${run}

echo ""

input=""
count=1
for i in "${pdbs[@]}"; do
  	echo "Now generating DSSP files for pdb ${i}"
	cp ../${i} .
	extension="${i##*.}"
	filename="${i%.*}"
	input="${input}--i${count} ${i} --d${count} ${filename}.dssp "
        count=`echo "${count}+1" | bc -l`
	mkdssp -i ${i} -o ${filename}.dssp	
done


if [ ${extra} == 1 ] ; then
	input_x=""
	count=1
	cp ../${extra_pdbs} . 

	while read i; do
  		cp ${i} .
		filename=`echo ${i} | rev | cut -d/ -f1 | rev`
		input_x="${input_x}${filename}  "
                count=`echo "${count}+1" | bc -l`
	done <${extra_pdbs}	
fi

echo "INPUT VARIABLES" > exprose.log
echo "param ${param}" >> exprose.log
echo "N ${N}" >> exprose.log

count=1
for i in "${pdbs[@]}"; do
	echo "input structure ${count}: ${i}" >> exprose.log
	count=`echo "${count}+1" | bc -l`
done

if [ ${extra} == 1 ] ; then
        count=1
	while read i; do
                filename=`echo ${i} | rev | cut -d/ -f1 | rev`
                echo "extra structure ${count}: ${filename}" >> exprose.log
		count=`echo "${count}+1" | bc -l`
        done <${extra_pdbs}
fi

if [ ${param} == 1 ]; then

	julia07 ~/.julia/packages/ProteinEnsembles/USEqV/bin/exprose-param ${input} -n ${N} -o exprose_param -t TMScore

	cp exprose_param/suggested.tsv .
	weight=`head -1 suggested.tsv`
	rm -r exprose_param
fi

if [ ${mod} == 0 ]; then
	if [ ${extra} == 0 ] ; then
		julia07 ~/.julia/packages/ProteinEnsembles/USEqV/bin/exprose ${input} -n ${N} -o exprose -w ${weight}

	elif [ ${extra} == 1 ] ; then
                julia07 ~/.julia/packages/ProteinEnsembles/USEqV/bin/exprose ${input} -n ${N} -o exprose -w ${weight} -e ${input_x}

	fi

elif [ ${mod} == 1 ]; then
	cp ../${mod_file} .
	if [ ${extra} == 0 ] ; then
		julia07 ~/.julia/packages/ProteinEnsembles/USEqV/bin/exprose ${input} -n ${N} -o exprose -w ${weight} -l ${mod_file} -m ${num_pockets}
	elif [ ${extra} == 1 ] ; then
                julia07 ~/.julia/packages/ProteinEnsembles/USEqV/bin/exprose ${input} -n ${N} -o exprose -w ${weight} -l ${mod_file} -m ${num_pockets} -e ${input_x}
	fi

	echo "mod file: ${mod_file}" >> exprose.log

fi

echo "weight ${weight}" >> exprose.log

echo ""
echo "Finished running ExProSE"
echo ""
echo "Now preparing pymol session(s)..."

cd exprose/pdbs
cp ${scripts}name_change.sh .
bash name_change.sh
cd ../
cp ${scripts}read_rmsfs.sh .
bash read_rmsfs.sh rmsfs.tsv input_1.pdb

cd pymol

cp ${scripts}get_pc_mag.sh .
ls | grep .txt > temp1

while read p; do
  bash get_pc_mag.sh $p  
done <temp1

rm temp1

cd ..



if [ ${mod} == 1 ]; then
	cd mod_1/
	cp ${scripts}read_rmsfs.sh .
	cp ../input_1.pdb .
	bash read_rmsfs.sh rmsfs_ratio.tsv input_1.pdb
	mv color_by_rmsfs.pml color_by_rmsfs_ratio.pml
	bash read_rmsfs.sh rmsfs.tsv input_1.pdb
	

	cd ../pdbs_mod_1/
	cp ${scripts}name_change.sh .
	bash name_change.sh
	cd ../../
fi


cd ../


