//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2024.2 (win64) Build 5239630 Fri Nov 08 22:35:27 MST 2024
//Date        : Tue Dec  2 15:38:59 2025
//Host        : Ariqfadhh running 64-bit major release  (build 9200)
//Command     : generate_target top_wrapper.bd
//Design      : top_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module top_wrapper
   (reset_rtl_0,
    sys_clock,
    uart_rtl_0_rxd,
    uart_rtl_0_txd);
  input reset_rtl_0;
  input sys_clock;
  input uart_rtl_0_rxd;
  output uart_rtl_0_txd;

  wire reset_rtl_0;
  wire sys_clock;
  wire uart_rtl_0_rxd;
  wire uart_rtl_0_txd;

  top top_i
       (.reset_rtl_0(reset_rtl_0),
        .sys_clock(sys_clock),
        .uart_rtl_0_rxd(uart_rtl_0_rxd),
        .uart_rtl_0_txd(uart_rtl_0_txd));
endmodule
