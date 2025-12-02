# Load variables
source tcl/set_variables.tcl

# Create build directories
if {![file isdirectory $dir_build_project_mode]} {
    file mkdir $dir_build_project_mode
}

set path_report $dir_origin/$dir_build_project_mode/$dir_report
if {![file isdirectory $path_report]} {
    file mkdir $path_report
}

set path_bitstream $dir_origin/$dir_build_project_mode/$dir_bitstream
if {![file isdirectory $path_bitstream]} {
    file mkdir $path_bitstream
}

# Create project
puts "INFO: Creating project ${project_name}..."
create_project ${project_name} ./${dir_project}/${project_name} -part ${fpga_part} -force

# Set board part (optional - only if board files installed)
# Uncomment if you have Digilent board files installed
# puts "INFO: Setting board part to ${board_part}..."
# set_property board_part $board_part [current_project]

# Generate Block Design
puts "INFO: Generating Block Design..."
source tcl/project-mode/generate_bd.tcl

# Verify top module is set
set top_module [get_property top [current_fileset]]
puts "INFO: Top module is set to: $top_module"

if {$top_module eq ""} {
    puts "ERROR: Top module not set!"
    return 1
}

# Add constraints
puts "INFO: Adding constraints..."
add_files -fileset constrs_1 -norecurse ./xdc/${filename_xdc}

# Update compile order one more time to be sure
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Run Synthesis
puts "INFO: Running Synthesis..."
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Run Implementation
puts "INFO: Running Implementation..."
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

# Copy bitstream to output directory
puts "INFO: Copying bitstream..."
file copy -force ./${dir_project}/${project_name}/${project_name}.runs/impl_1/top_wrapper.bit $path_bitstream/$filename_bitstream

puts "INFO: Build completed successfully!"
puts "INFO: Bitstream saved to: $path_bitstream/$filename_bitstream"