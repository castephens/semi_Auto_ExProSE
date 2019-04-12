#!bin.bash

#Author: Christina Stephens
#Date: 01/22/19

if [ -f list_of_structs.txt ] ; then
    rm list_of_structs.txt
    rm list2.txt
fi

ls | grep pdb > list_of_structs.txt

where=`pwd`

while read p; do
  mv $p ${p}.pdb
  echo "${where}/${p}.pdb" >> list2.txt
done <list_of_structs.txt

rm list_of_structs.txt
mv list2.txt list_of_pdbs.txt


