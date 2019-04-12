#!bin/bash


pc_coords=$1

num_pts=`wc -l ${pc_coords} | awk '{print $1}'`

count=2

echo "gathering PC magnitudes for ${pc_coords}"

for i in `seq 1 2 $num_pts` ; do
	x_1=`awk 'NR=='$i'{print $1}' $pc_coords`
	x_2=`awk 'NR=='$count'{print $1}' $pc_coords` 
	
	y_1=`awk 'NR=='$i'{print $2}' $pc_coords`
        y_2=`awk 'NR=='$count'{print $2}' $pc_coords` 

	z_1=`awk 'NR=='$i'{print $3}' $pc_coords`
        z_2=`awk 'NR=='$count'{print $3}' $pc_coords` 


	dist=`echo "sqrt((($x_1 - $x_2)^2) + (($y_1 - $y_2)^2) + (($z_1 - $z_2)^2))" | bc -l`
	
	echo $dist >> temp
	
	count=`echo "$count + 2" | bc -l`

done

rm ${pc_coords} 
mv temp ${pc_coords}


