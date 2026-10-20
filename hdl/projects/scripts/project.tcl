
set script_dir [ file dirname [ file normalize [ info script ] ] ]
set project_dir [pwd]
set root_dir   "$script_dir/../.."
set lib_dir    "$root_dir/lib"
set boards_dir "$root_dir/boards"
set build_dir  "$project_dir/build"

set_param board.repoPaths [list $boards_dir]

# Créer un projet.
create_project system_prj build -force

set_property target_language VHDL [current_project]

# Créer et remplir le diagramme de blocs.
create_bd_design system_bd

source "$script_dir/common.tcl"
source "$project_dir/system.tcl"

save_bd_design
validate_bd_design
