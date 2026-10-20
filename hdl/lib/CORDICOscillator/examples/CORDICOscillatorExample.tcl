
set script_path [ file dirname [ file normalize [ info script ] ] ]

source $script_path/../../scripts/common.tcl

set module CORDICOscillator

syn_helper ${module}Example xc7z020clg484-1 "
    $script_path/../../fixed_pkg/src/fixed_pkg.vhd
    $script_path/../../fixed_pkg/src/fixed_pkg_RTL.vhd
    $script_path/../build/examples/${module}Example_cfg.vhd
    $script_path/../build/examples/CORDIC_pkg.vhd
    $script_path/../../CORDIC/src/CORDIC.vhd
    $script_path/../../CORDIC/src/CORDIC_RTL.vhd
    $script_path/../src/${module}.vhd
    $script_path/../src/${module}_RTL.vhd
    $script_path/${module}Example.vhd
"
