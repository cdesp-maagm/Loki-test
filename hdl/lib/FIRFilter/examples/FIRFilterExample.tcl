
set script_dir [ file dirname [ file normalize [ info script ] ] ]
set lib_dir "$script_dir/../.."

source $script_dir/../../scripts/common.tcl

set module FIRFilter

syn_helper ${module}Example xc7z020clg484-1 "
    $lib_dir/fixed_pkg/src/fixed_pkg.vhd
    $lib_dir/fixed_pkg/src/fixed_pkg_RTL.vhd
    $lib_dir/DelayLine/src/DelayLine.vhd
    $lib_dir/DelayLine/src/DelayLine_ShiftRegisters.vhd
    $lib_dir/FIFOController/src/FIFOController.vhd
    $script_dir/../build/examples/${module}Example_cfg.vhd
    $script_dir/../build/examples/${module}_pkg.vhd
    $script_dir/../build/examples/${module}Example_pkg.vhd
    $script_dir/../src/${module}.vhd
    $script_dir/../src/${module}_RTL.vhd
    $script_dir/${module}Example.vhd
"
