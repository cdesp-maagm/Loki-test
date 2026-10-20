
set script_path [ file dirname [ file normalize [ info script ] ] ]

source $script_path/../../scripts/common.tcl

set module DelayLine

foreach arch {RAM ShiftRegisters} {
    syn_helper ${module}${arch}Example xc7z020clg484-1 "
        $script_path/../../fixed_pkg/src/fixed_pkg.vhd
        $script_path/../src/${module}.vhd
        $script_path/../src/${module}_${arch}.vhd
        $script_path/${module}Examples_cfg.vhd
        $script_path/${module}${arch}Example.vhd
    "
}
