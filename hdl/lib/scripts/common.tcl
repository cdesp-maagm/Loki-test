
proc syn_helper {project_name part_name src} {
    create_project -force -part $part_name $project_name build
    read_vhdl -vhdl2008 $src
    launch_runs impl_1
    wait_on_run impl_1
    open_run impl_1
    report_utilization -file build/$project_name-utilization.log
    report_timing_summary -file build/$project_name-timing.log
    close_project
}
