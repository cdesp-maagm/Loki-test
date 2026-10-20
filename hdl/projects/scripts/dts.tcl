
set script_dir [ file dirname [ file normalize [ info script ] ] ]

set build_dir [pwd]/build
set hdf_file "$build_dir/system.hdf"

open_hw_design "$hdf_file"
set cpu_name [lindex [get_cells -filter {IP_TYPE==PROCESSOR}] 0]

set_repo_path "$script_dir/../../device-tree-xlnx"
create_sw_design device-tree -os device_tree -proc $cpu_name
generate_target -dir "$build_dir"
