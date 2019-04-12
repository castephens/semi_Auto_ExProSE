#! bin/bash

#Author: Christina Stephens
#Date: 02/19/19

mod1='GNP_MG_1ibr'
mod2='P184_1k5d_dummy'

# uncomment if located in different directory
#cp ${mod1}.pdb .
#cp ${mod2}.pdb .

for i in `seq 0 2` ; do
	cp ${mod1}.pdb ${mod1}_${i}.pdb
	sed -i "s/[^[:blank:]]\{1,\}/${i}/5" ${mod1}_${i}.pdb
	for j in `seq 2 -1 0` ; do
		cp ${mod2}.pdb ${mod2}_${j}.pdb
		sed -i '1d' ${mod2}_${j}.pdb
		sed -i "s/[^[:blank:]]\{1,\}/${j}/5" ${mod2}_${j}.pdb
		cat ${mod1}_${i}.pdb ${mod2}_${j}.pdb > ${mod1}_${mod2}_${i}${j}.pdb
		bash master_script_ExProSE.sh -p N -s "3gj0_dCterm.pdb 1ibr_dCterm.pdb" -n 200 -w 0.3 -m ${mod1}_${mod2}_${i}${j}.pdb
		rm ${mod2}_${j}.pdb ${mod1}_${mod2}_${i}${j}.pdb
	done
	rm ${mod1}_${i}.pdb
done
