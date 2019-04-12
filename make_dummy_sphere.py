# Author: Christina Stephens
# Date: 02/24/2019

import sys
import math

X = sys.argv[1]
Y = sys.argv[2]
Z = sys.argv[3]

X = float(X)
Y = float(Y)
Z = float(Z)

#X = 35.474
#Y = 7.037
#Z = -19.944

r = 7.0

N_count = 0
N = 15000
a = (4*(math.pi)*(r*r))/N
d = math.sqrt(a)
M_theta = int(round((math.pi)/d))
d_theta = (math.pi)/M_theta
d_phi = a/d_theta

sphere = [[],[],[]]
sel = 'select dummies, '
with open('dummy_sphere.pml', 'a') as f:
    for m in range(0,M_theta):
        theta = ((math.pi)*(float(m)+0.5))/float(M_theta)
        M_phi = int(round(((math.pi)*(math.sin(theta)))/d_theta))
        for n in range(0,M_phi):
            phi = (2*(math.pi)*n)/M_phi
        
            x = r*math.sin(theta)*math.cos(phi) + X
            y = r*math.sin(theta)*math.sin(phi) + Y
            z = r*math.cos(theta) + Z
        
            N_count += 1
            
            f.write('pseudoatom dum' + str(N_count) + ' ,pos=[' + str(x) + ', ' + str(y) + ', ' + str(z) + ']\n')
            if m == 0:
                sel = sel + ' dum' + str(N_count)
            else:
                sel = sel + ' or dum' + str(N_count)
        
            sphere[0].append(r*math.sin(theta)*math.cos(phi) + X)
            sphere[1].append(r*math.sin(theta)*math.sin(phi) + Y)
            sphere[2].append(r*math.cos(theta) + Z)
        
    f.write(sel + '\n') 
    f.write('save dummy_sphere.pdb, dummies\n')

print('Number of dummies made: ' + str(N_count)) 
