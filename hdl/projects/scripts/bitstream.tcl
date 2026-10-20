
set project_dir [pwd]
set build_dir "$project_dir/build"

set jobs 8

open_project "$build_dir/system_prj.xpr"

set bd [get_files "$build_dir/system_prj.srcs/sources_1/bd/system_bd/system_bd.bd"]

# Créer l'entité principale qui instancie le diagramme.
make_wrapper -files $bd -top
add_files -norecurse "$build_dir/system_prj.srcs/sources_1/bd/system_bd/hdl/system_bd_wrapper.vhd"
set_property top system_bd_wrapper [current_fileset]

# Par défaut, les ports bidirectionnels des blocs IP ne sont pas bien
# pris en charge lorsqu'on les synthétise séparément (Out-Of-Context).
# Cette option force la synthèse globale du design.
set_property synth_checkpoint_mode None $bd

# Générer le bitstream.
update_compile_order -fileset sources_1
reset_run impl_1

launch_runs impl_1 -jobs $jobs
wait_on_run impl_1
open_run impl_1
write_bitstream -force -bin_file "$build_dir/system.bit"
write_hwdef -force "$build_dir/system.hdf"
