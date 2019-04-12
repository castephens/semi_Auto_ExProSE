#! bin/bash

#Author: Christina Stephens
#Date: 02/19/19


mod='GNP_MG_1k5d'

# uncomment if located in different directory
#cp ${mod}.pdb .

for i in `seq 0 2` ; do
        cp ${mod}.pdb ${mod}_${i}.pdb
        sed -i "s/[^[:blank:]]\{1,\}/${i}/5" ${mod}_${i}.pdb
        bash master_script_ExProSE.sh -p N -s "final_3gj0.pdb final_1k5d.pdb" -n 200 -w 0.3 -m ${mod}_${i}.pdb
	rm ${mod}_${i}.pdb
done

