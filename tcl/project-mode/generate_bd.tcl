source tcl/set_variables.tcl

puts "INFO: Creating Block Design '${top_level}' with MicroBlaze RISC-V ..."

# -----------------------------------------------------------------------------
# Ensure project exists and BOARD_PART is set 
# -----------------------------------------------------------------------------
if {[current_project -quiet] eq ""} {
    puts "WARNING: No project open. Creating temporary project."
    create_project temp_proj ./temp_proj -part xc7a100tcsg324-1
}

# -----------------------------------------------------------------------------
# Create Block Design
# -----------------------------------------------------------------------------
create_bd_design ${top_level}

# -----------------------------------------------------------------------------
# Create main IPs
# -----------------------------------------------------------------------------
create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze_riscv:1.0 microblaze_riscv_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 axi_uartlite_0

# -----------------------------------------------------------------------------
# Apply MicroBlaze RISC-V automation (creates clk_wiz_1, rst, local mem, etc.)
# -----------------------------------------------------------------------------
apply_bd_automation -rule xilinx.com:bd_rule:microblaze_riscv \
  -config { \
    axi_intc {0} \
    axi_periph {Enabled} \
    cache {None} \
    clk {New Clocking Wizard} \
    debug_module {Debug Enabled} \
    ecc {None} \
    local_mem {16KB} \
    preset {None} \
  } [get_bd_cells microblaze_riscv_0]

# -----------------------------------------------------------------------------
# WAIT for clk_wiz_1 to be fully created 
# -----------------------------------------------------------------------------
puts "INFO: Waiting for Clocking Wizard (clk_wiz_1) to be ready..."
set retry 0
while {[get_bd_cells -quiet clk_wiz_1] eq ""} {
    after 100
    incr retry
    if {$retry > 50} {
        error "FATAL: clk_wiz_1 not created after 5 seconds!"
    }
}
puts "INFO: clk_wiz_1 is ready."

# -----------------------------------------------------------------------------
# sys_clock PORT MANUALLY and CONNECT DIRECTLY 
# -----------------------------------------------------------------------------
puts "INFO: Creating sys_clock port and connecting manually..."

# Create sys_clock port if not exists
if {[get_bd_ports -quiet sys_clock] eq ""} {
    set sys_clk [create_bd_port -dir I -type clk sys_clock]
    set_property CONFIG.FREQ_HZ 100000000 $sys_clk
    puts "INFO: Created sys_clock (100 MHz)."
} else {
    set sys_clk [get_bd_ports sys_clock]
}

# Configure Clocking Wizard for single-ended input
set_property CONFIG.PRIM_SOURCE Single_ended_clock_capable_pin [get_bd_cells clk_wiz_1]
set_property CONFIG.CLK_IN1_BOARD_INTERFACE Custom [get_bd_cells clk_wiz_1]

# 🔌 DIRECT CONNECTION — THIS GUARANTEES CLK_IN1 IS CONNECTED
connect_bd_net $sys_clk [get_bd_pins clk_wiz_1/clk_in1]
puts "SUCCESS: sys_clock → clk_wiz_1/clk_in1"

# -----------------------------------------------------------------------------
# Connect AXI Uartlite via AXI4
# -----------------------------------------------------------------------------
apply_bd_automation -rule xilinx.com:bd_rule:axi4 \
  -config { \
    Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} \
    Clk_slave {Auto} \
    Clk_xbar {Auto} \
    Master {/microblaze_riscv_0 (Periph)} \
    Slave {/axi_uartlite_0/S_AXI} \
    ddr_seg {Auto} \
    intc_ip {New AXI SmartConnect} \
    master_apm {0} \
  } [get_bd_intf_pins axi_uartlite_0/S_AXI]

# -----------------------------------------------------------------------------
# Connect USB UART using board automation (safe because BOARD_PART is set)
# -----------------------------------------------------------------------------
apply_bd_automation -rule xilinx.com:bd_rule:board \
  -config { Board_Interface {usb_uart ( USB UART ) } Manual_Source {Auto}} \
  [get_bd_intf_pins axi_uartlite_0/UART]

# -----------------------------------------------------------------------------
# Connect RESET using board automation
# -----------------------------------------------------------------------------
apply_bd_automation -rule xilinx.com:bd_rule:board \
  -config { Board_Interface {reset ( Reset ) } Manual_Source {Auto}} \
  [get_bd_pins clk_wiz_1/reset]

apply_bd_automation -rule xilinx.com:bd_rule:board \
  -config { Board_Interface {reset ( Reset ) } Manual_Source {Auto}} \
  [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in]

# -----------------------------------------------------------------------------
# Finalize
# -----------------------------------------------------------------------------
regenerate_bd_layout
validate_bd_design

puts "INFO: Saving block design..."
save_bd_design

# -----------------------------------------------------------------------------
# Generate HDL wrapper
# -----------------------------------------------------------------------------
puts "INFO: Generating IP targets and wrapper..."
set bd_file [get_files ${top_level}.bd]
generate_target all $bd_file
export_ip_user_files -of_objects $bd_file -no_script -sync -force -quiet

set wrapper_file [make_wrapper -files $bd_file -top]
add_files -norecurse $wrapper_file

# Copy to RTL dir
set wrapper_filename [file tail $wrapper_file]
file copy -force $wrapper_file ./$dir_rtl/$wrapper_filename

# Set as top
set_property top ${top_level}_wrapper [current_fileset]
set_property top_lib xil_defaultlib [current_fileset]
update_compile_order -fileset sources_1

puts "Block design '${top_level}' created successfully with single-ended sys_clock!"