# Create Clock Wizard
create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 \
          -module_name clk_wiz_0 -dir $ip_dir

set_property -dict [list \
    CONFIG.PRIM_IN_FREQ {100.0} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {50.0} \
] [get_ips clk_wiz_0]

# Create AXI GPIO
create_ip -name axi_gpio -vendor xilinx.com -library ip -version 2.0 \
          -module_name axi_gpio_0 -dir $ip_dir

set_property -dict [list \
    CONFIG.C_GPIO_WIDTH {4} \
    CONFIG.C_ALL_OUTPUTS {1} \
] [get_ips axi_gpio_0]

# Generate RTL for all IPs
generate_target all [get_ips]
synth_ip [get_ips]

# Read RTL
read_verilog [glob -nocomplain "$rtl_dir/*.v"]

# Include generated IP outputs
read_verilog [glob -nocomplain "$ip_dir/**/*.v"]

# Synthesize top
synth_design -top top -part xc7a100tcsg324-1

write_verilog -force top_synth.v
write_bitstream -force top.bit