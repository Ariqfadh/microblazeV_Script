source tcl/set_variables.tcl

set_part $fpga_part

#Step 0: Reading and Generating IPs
set xci_list {}

# iterate subfolders under /ip
foreach dir [glob -type d "$dir_origin/$dir_ip/*"] {
    foreach xci [glob -nocomplain "$dir/*.xci"] {
        lappend xci_list $xci
    }
}

if {[llength $xci_list] == 0} {
    puts "WARNING: NO XCI FILES FOUND!"
} else {
    puts "Found XCI files:"
    foreach xci $xci_list { puts "  $xci" }

    foreach ip $xci_list { read_ip $ip }
    upgrade_ip [get_ips]
    generate_target all [get_ips]
}

#Step 1: Reading RTL
#read_verilog "$dir_origin/$dir_rtl/top_alu.v"
read_verilog [glob "$dir_origin/$dir_rtl/*.v"]

if {![file isdirectory $dir_build_non_project_mode]} {
    file mkdir $dir_build_non_project_mode
}

set path_report $dir_origin/$dir_build_non_project_mode/$dir_report
if {![file isdirectory $path_report]} {
    file mkdir $path_report
}

set path_bitstream $dir_origin/$dir_build_non_project_mode/$dir_bitstream
if {![file isdirectory $path_bitstream]} {
    file mkdir $path_bitstream
}

#Step 6: Running Synthesis
read_xdc "$dir_origin/$dir_xdc/$filename_xdc"
synth_design -top $top_level
write_checkpoint -force $dir_build_non_project_mode/post_synth.dcp
report_timing_summary -file $path_report/timing_syn.rpt


#Step 7: Running Implementation
opt_design
place_design
write_checkpoint -force $dir_build_non_project_mode/post_place.dcp
report_timing -file $path_report/timing_place.rpt
phys_opt_design
route_design
write_checkpoint -force $dir_build_non_project_mode/post_route.dcp
report_timing_summary -file $path_report/timing_summary
write_bitstream -force $path_bitstream/$filename_bitstream