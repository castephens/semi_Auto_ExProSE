print("")
print("_______________________________")
print("_______import everything_______")
print("_______________________________")
print("")

#Python
from pyrosetta import *

#Core Includes
from rosetta.core.kinematics import MoveMap
from rosetta.core.kinematics import FoldTree
from rosetta.core.pack.task import TaskFactory
from rosetta.core.pack.task import operation
from rosetta.core.simple_metrics import metrics
from rosetta.core.select import residue_selector as selections
from rosetta.core.select.movemap import *

#Protocol Includes
from rosetta.protocols import minimization_packing as pack_min
from rosetta.protocols import relax as rel
from rosetta.protocols.antibody.residue_selector import CDRResidueSelector
from rosetta.protocols.antibody import *
from rosetta.protocols.loops import *
from rosetta.protocols.relax import FastRelax
import sys


fn = sys.argv[1]


#Intitlialization (Setting relax rounds to 2 instead of default 5 for speed of demo)
init('-ex1 -ex2 -use_input_sc -input_ab_scheme AHo_Scheme -ignore_unrecognized_res \
     -ignore_zero_occupancy false -load_PDB_components false')

pyrosetta.rosetta.basic.options.set_boolean_option('relax:constrain_relax_to_start_coords', True)
pyrosetta.rosetta.basic.options.set_boolean_option('relax:ramp_constraints', True)


print("")
print("_______________________________")
print("___________intro PDB___________")
print("_______________________________")
print("")

#Import a pose
pose = pose_from_pdb(str(fn)+".pdb")
pose2 = pose_from_pdb(str(fn)+".pdb")
original_pose = pose.clone()


#Setup a normal TaskFactory
tf = TaskFactory()
tf.push_back(operation.InitializeFromCommandline())
tf.push_back(operation.RestrictToRepacking())   #NOT DESIGN

#Why push back?

print("")
print("_______________________________")
print("_________Packer Setup__________")
print("_______________________________")
print("")

#Setup The packer
packer = pack_min.PackRotamersMover()
packer.task_factory(tf) 

#Note that we are not passing a scorefunction here.  We will use the default, cmd-line scorefunction, 
# which is access through rosetta.core.scoring.get_score_function().  We use use a scorefunction later. 

#Run the packer. (Note this may take a few minutes)
packer.apply(pose)

#Dump the PDB
pose.dump_pdb(str(fn)+'_repack.pdb')

print("")
print("_______________________________")
print("________Old v Re-Packed________")
print("_______________________________")
print("")

#Lets compare the energies of the before and after pose. Any difference?
scorefxn = get_score_function()
before = scorefxn.score(original_pose)
after = scorefxn.score(pose)

print('Score before packing:', before)
print('Score after packing:', after)
#Finish the code here


print("")
print("_______________________________")
print("____________Relax______________")
print("_______________________________")
print("")

#Lets first relax the whole protein.  This will take a few minutes, so after you run it, take a break and stretch!


fr = FastRelax()

#Here, we have to set a scorefunction or we segfault.  
#  Error checking is important, and protocols should use a default scorefunction. We will manage.

scorefxn = get_score_function()
fr.set_scorefxn(scorefxn)

#Lets run this.  This takes a very long time, so we are going decrease the amount of minimization cycles we use.
# This is generally only recommended for cartesian, but we just want everything to run fast at the moment.
#fr.max_iter(200)


#Run the code
#fr.apply(pose_rep)
fr.apply(pose2)

#Dump the pdb and take a look.
pose2.dump_pdb(str(fn)+'_relax.pdb')

print("")
print("_______________________________")
print("________Old v Relaxed________")
print("_______________________________")
print("")

#Lets compare the energies of the before and after pose. Any difference?
before = scorefxn.score(original_pose)
after = scorefxn.score(pose2)

print('Score before relaxing:', before)
print('Score after relaxing:', after)
#Finish the code here

print("")
print("_______________________________")
print("______Relax the Repack_________")
print("_______________________________")
print("")

#Lets first relax the whole protein.  This will take a few minutes, so after you run it, take a break and stretch!


fr = FastRelax()

#Here, we have to set a scorefunction or we segfault.  
#  Error checking is important, and protocols should use a default scorefunction. We will manage.

scorefxn = get_score_function()
fr.set_scorefxn(scorefxn)

#Lets run this.  This takes a very long time, so we are going decrease the amount of minimization cycles we use.
# This is generally only recommended for cartesian, but we just want everything to run fast at the moment.
#fr.max_iter(200)


#Run the code
#fr.apply(pose_rep)
fr.apply(pose)

#Dump the pdb and take a look.
pose.dump_pdb(str(fn)+'_repacked_and_relax.pdb')

print("")
print("_______________________________")
print("__Old v Repacked and Relaxed___")
print("_______________________________")
print("")

#Lets compare the energies of the before and after pose. Any difference?
before = scorefxn.score(original_pose)
after = scorefxn.score(pose)

print('Score before relaxing:', before)
print('Score after relaxing:', after)
#Finish the code here





