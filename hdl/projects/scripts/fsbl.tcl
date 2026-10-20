
set build_dir [pwd]/build
set hdf_file "$build_dir/system.hdf"

hsi open_hw_design "$hdf_file"
set cpu_name [lindex [hsi get_cells -filter {IP_TYPE==PROCESSOR}] 0]

sdk setws "$build_dir/sdk"
sdk createhw -name hw_0 -hwspec "$hdf_file"
sdk createapp -name fsbl -hwproject hw_0 -proc $cpu_name -os standalone -lang C -app {Zynq FSBL}
configapp -app fsbl build-config release
sdk projects -build -type all
