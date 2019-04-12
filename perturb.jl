# Generate new interactions to perturb ensembles


export
    repeatpocketpoints,
    perturbensemble,
    clusterligsite


"""
Find new interactions arising from fake modulator atoms and form a new `Constraints` object.
Arguments are atoms to calculate constraints with, `Constraints` object to add to, generated modulator
coordinates, distance cutoff and constraint tolerances for intra-modulator and modulator-protein
interactions, and minimum lower distance constraint.
Returns a new `Constraints` object including the modulator.
"""
function Constraints(atoms::Array{Atom,1},
                    old_constraints::Constraints,
                    mod_coords::Array{Float64},
                    mod_weights::Array{Float64};       #christina
		    intra_cutoff::Real=defaults["mod_intra_cutoff"], # If this is 0.0 there are no intra-modulator interactions
                    intra_tolerance::Real=defaults["mod_intra_tolerance"],
                    inter_cutoff::Real=defaults["mod_inter_cutoff"],
                    inter_tolerance::Real=defaults["mod_inter_tolerance"],
                    min_constraint_dist::Real=defaults["mod_min_constraint_dist"])
    n_atoms = length(atoms)
    @assert n_atoms > 0 "No atoms in atom list"
    constraint_atoms = old_constraints.atoms
    @assert n_atoms == length(constraint_atoms) "Different number of atoms in atom list and constraints"
    n_constraints = size(old_constraints.pres_inds, 1)
    @assert n_constraints == length(old_constraints.lower) && n_constraints == length(old_constraints.upper) "The number of lower and upper constraints do not correspond to the number of constraints present"
    n_mod_atoms = size(mod_coords, 2)
    @assert n_mod_atoms > 0 "No modulator coordinates in list"
    @assert intra_cutoff >= 0 "intra_cutoff cannot be negative"
    @assert intra_tolerance >= 0 "intra_tolerance cannot be negative"
    @assert inter_cutoff >= 0 "inter_cutoff cannot be negative"
    @assert inter_tolerance >= 0 "inter_tolerance cannot be negative"
    @assert min_constraint_dist >= 0 "min_constraint_dist cannot be negative"
    n_total = n_atoms + n_mod_atoms
    # Copy Constraints object and form larger constraints lists
    new_lower = copy(old_constraints.lower)
    new_upper = copy(old_constraints.upper)
    new_pres_inds = copy(old_constraints.pres_inds)
    new_atoms = deepcopy(constraint_atoms)
    # Add new atoms to atom array
    for i in 1:n_mod_atoms
        push!(new_atoms, Atom(mod_atom_info["atom_name"], mod_atom_info["res_name"], mod_atom_info["chain_id"], mod_atom_info["res_n"], mod_coords[:,i], mod_atom_info["element"]))
    end
    new_inds_i = Int[]
    new_inds_j = Int[]
    # Find interactions within modulator
    intra_counter = 0
    intra_cutoff_sq = intra_cutoff^2
    for i in 1:n_mod_atoms
        for j in 1:(i-1)
            sq_dist = 0.0
            for m = 1:3
                sq_dist += abs2(mod_coords[m,i] - mod_coords[m,j])
            end
            if sq_dist < intra_cutoff_sq
                dist = sqrt(sq_dist)
                push!(new_lower, max(dist-intra_tolerance, min_constraint_dist))
                push!(new_upper, dist+intra_tolerance)
                push!(new_inds_i, n_atoms+i)
                push!(new_inds_j, n_atoms+j)
                intra_counter += 1
            end
        end
    end
    # Find interactions between modulator and protein
    inter_counter = 0
    inter_cutoff_sq = inter_cutoff^2
    for i in 1:n_mod_atoms
	#println(mod_weights[i])        #christina
        for j in 1:n_atoms
            sq_dist = 0.0
            for m = 1:3
                sq_dist += abs2(mod_coords[m,i] - atoms[j].coords[m])
            end
            if sq_dist < inter_cutoff_sq
                dist = sqrt(sq_dist)
		if mod_weights[i] == 0
			inter_tolerance = 0.1
		else
			inter_tolerance = mod_weights[i]
		end
                push!(new_lower, max(dist-inter_tolerance, min_constraint_dist))
                push!(new_upper, dist+inter_tolerance)
                push!(new_inds_i, n_atoms+i)
                push!(new_inds_j, j)
                inter_counter += 1
            end
        end
    end
    if length(new_pres_inds) > 0
        new_pres_inds = vcat(new_pres_inds, hcat(new_inds_i, new_inds_j))
    else
        new_pres_inds = hcat(new_inds_i, new_inds_j)
    end
    #println("Found ", intra_counter, " interactions within the modulator")
    println("Found ", inter_counter, " interactions between the modulator and the protein")
    return Constraints(new_atoms, new_lower, new_upper, new_pres_inds)
end


"""
Repeat pocket point to get a certain number of points.
Points are repeated as long as whole copies can be made, then the remainder are chosen randomly.
Returns coordinate array.
"""
function repeatpocketpoints(coords::Array{Float64}, n_out_points::Integer=defaults["mod_n_points"])
    n_pocket_points = Int(length(coords) / 3)
    inds_to_use = repeat(collect(1:n_pocket_points), outer=[Int(floor(n_out_points / n_pocket_points))])
    append!(inds_to_use, rand(1:n_pocket_points, n_out_points % n_pocket_points))
    return getindex(coords, collect(1:3), inds_to_use)
end


"""
Gets ensembles for multiple modulators.
Use pocket points to generate additional constraints.
"""
function perturbensemble(atoms::Array{Atom,1},
                    constraints::Constraints,
                    n_strucs::Integer,
                    mod_path::Union{AbstractString, Nothing},
                    n_mods::Integer)
    ensemble_mods = ModelledEnsemble[]
    if n_mods > 0 && mod_path != nothing
        pock_points = readpocketpoints(mod_path)
	pocket_weights = readpocketweight(mod_path)                    #christina
	#println(pocket_weights)
        n_pocks = length(pock_points)
        if n_mods > n_pocks
            println(n_mods, " modulators asked for but only ", n_pocks, " found")
        end
        n_mods_to_use = min(n_mods, n_pocks)
        for i in 1:n_mods_to_use
            println("Generating ensemble with modulator ", i, " of ", n_mods_to_use)
            mod_coords = repeatpocketpoints(pock_points[i])
            #new_constraints = Constraints(atoms, constraints, mod_coords)
            new_constraints = Constraints(atoms, constraints, mod_coords, pocket_weights[i])  #christina
	    push!(ensemble_mods, generateensemble(new_constraints, n_strucs))
        end
    end
    return ensemble_mods
end


"""
Assign pocket numbers to LIGSITEcs pocket_r.pdb file points.
Arguments are pocket_r.pdb file, pocket_all.pdb file and new pocket_r.pdb file.
New file has pocket number in place of residue number.
Apears to agree largely but not completely with the LIGSITEcs clustering.
Unassigned points given number 0 and should be fixed manually.
"""
function clusterligsite(point_filepath::AbstractString,
                    centre_filepath::AbstractString,
                    out_filepath::AbstractString;
                    cluster_dist::Real=defaults["cluster_dist"])
    point_lines = readpdblines(point_filepath)
    n_points = length(point_lines)
    point_coords = zeros(3, n_points)
    for (i, line) in enumerate(point_lines)
        point_coords[1,i] = parse(Float64, line[31:38])
        point_coords[2,i] = parse(Float64, line[39:46])
        point_coords[3,i] = parse(Float64, line[47:54])
    end
    println("Read ", n_points, " pocket points from LIGSITEcs pocket points PDB file")
    centre_coords, centre_vols = readligsite(centre_filepath)
    n_centres = length(centre_vols)
    assignments = zeros(Int, n_points)

    # Assign points within cluster_dist Angstroms of a centre to belong to the largest pocket centre
    for p in 1:n_points
        centre_closest = 0
        dist_closest = cluster_dist
        for c in n_centres:-1:1
            dist = norm(point_coords[:,p] - centre_coords[:,c])
            if dist <= cluster_dist
                centre_closest = c
                dist_closest = dist
            end
        end
        assignments[p] = centre_closest
    end

    # While some are still unassigned and have not stalled
    n_unassigned = 2 # Placeholder
    new_n_unassigned = 1 # Placeholder
    while new_n_unassigned != n_unassigned && new_n_unassigned > 0
        n_unassigned = sum(x -> x == 0, assignments)
        for p in 1:n_points
            # For each unassigned point
            if assignments[p] == 0
                point_closest = 0
                dist_closest = cluster_dist
                for a in 1:n_points
                    # Check each assigned point
                    if assignments[a] > 0
                        dist = norm(point_coords[:,p] - point_coords[:,a])
                        # Assign it if it within cluster_dist Angstroms and not already assigned to a larger pocket
                        if dist <= cluster_dist && (point_closest == 0 || assignments[a] < assignments[point_closest])
                            point_closest = a
                            dist_closest = dist
                        end
                    end
                end
                if point_closest > 0
                    assignments[p] = assignments[point_closest]
                end
            end
        end
        new_n_unassigned = sum(x -> x == 0, assignments)
    end
    if new_n_unassigned > 0
        println("Could not assign ", new_n_unassigned, " points")
    else
        println("Assigned all points")
    end

    writeclusterpoints(out_filepath, point_lines, assignments)
end
