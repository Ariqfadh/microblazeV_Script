source tcl/0_set_variables.tcl

set dir_path $dir_report

if {![file isdirectory $dir_path]} {
    file mkdir $dir_path
    puts "Directory '$dir_path' created."
} else {
    puts "Directory '$dir_path' already exists."
}