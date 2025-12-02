source tcl/set_variables.tcl

set path_file_bitstream $dir_origin/$dir_build_non_project_mode/$dir_bitstream/$filename_bitstream

open_hw_manager
connect_hw_server
current_hw_target
open_hw_target
set_property PROGRAM.FILE $path_file_bitstream [current_hw_device]
program_hw_devices [current_hw_device]