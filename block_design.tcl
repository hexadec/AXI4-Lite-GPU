set output_resolution "1920x1080"

if {$output_resolution == "640x480"} {
  # 60 Hz
  set param_fbuf_addr_width 19;
  set param_fbuf_data_width 24;
  set param_frame_scaling_factor 1;
  set param_frame_width 640;
  set param_frame_height 480;
} elseif {$output_resolution == "800x600"} {
  # 60 Hz
  set param_fbuf_addr_width 17;
  set param_fbuf_data_width 24;
  set param_frame_scaling_factor 2;
  set param_frame_width 800;
  set param_frame_height 600;
} elseif {$output_resolution == "1280x720"} {
  # 60 Hz
  set param_fbuf_addr_width 18;
  set param_fbuf_data_width 24;
  set param_frame_scaling_factor 2;
  set param_frame_width 1280;
  set param_frame_height 720;
} elseif {$output_resolution == "1920x1080"} {
  # 60 Hz
  set param_fbuf_addr_width 17;
  set param_fbuf_data_width 24;
  set param_frame_scaling_factor 4;
  set param_frame_width 1920;
  set param_frame_height 1080;
} elseif {$output_resolution == "2560x1440"} {
  # 30 Hz
  set param_fbuf_addr_width 18;
  set param_fbuf_data_width 24;
  set param_frame_scaling_factor 4;
  set param_frame_width 2560;
  set param_frame_height 1440;
} elseif {$output_resolution == "3840x2160"} {
  # 24 Hz
  set param_fbuf_addr_width 17;
  set param_fbuf_data_width 24;
  set param_frame_scaling_factor 8;
  set param_frame_width 3840;
  set param_frame_height 2160;
} else {
  error "Invalid output resolution"
}

set script_location [file normalize [info script]]
set project_folder [file dirname $script_location]
set project_folder_split [split $project_folder /]
set project_name [lindex $project_folder_split end]
puts "Project folder: ${project_folder}"
puts "Project name: ${project_name}"

open_project ${project_folder}/${project_name}.xpr

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
update_ip_catalog

open_bd_design "${project_folder}/block_design/design_1/design_1.bd"

set bd_items [get_bd_cells]
delete_bd_objs ${bd_items}
set bd_items [get_bd_ports]
delete_bd_objs ${bd_items}
set bd_items [get_bd_nets]
delete_bd_objs ${bd_items}
set bd_items [get_bd_pins]
delete_bd_objs ${bd_items}
set bd_items [get_bd_intf_ports]
delete_bd_objs ${bd_items}
set bd_items [get_bd_intf_nets]
delete_bd_objs ${bd_items}
set bd_items [get_bd_intf_pins]
delete_bd_objs ${bd_items}

startgroup

create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config { \
	make_external "FIXED_IO, DDR" \
	apply_board_preset "1" \
	Master "Disable" \
	Slave "Disable" \
} [get_bd_cells processing_system7_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0
create_bd_cell -type ip -vlnv digilentinc.com:ip:rgb2dvi:1.4 rgb2dvi_0
create_bd_cell -type module -reference block block_0
create_bd_cell -type module -reference fbuf2rgb fbuf2rgb_0
create_bd_cell -type module -reference color_converter color_converter_0
create_bd_cell -type module -reference axi4_lite_gpu axi4_lite_gpu_0

create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconn_gpu_2_ddr
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconn_gp0_2_gpu
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconn_gp1_2_vdma
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconn_vdma_2_ddr

set_property -dict [list \
  CONFIG.PCW_APU_PERIPHERAL_FREQMHZ {650} \
  CONFIG.PCW_UIPARAM_DDR_FREQ_MHZ {525} \
  CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} \
  CONFIG.PCW_EN_CLK1_PORT {1} \
  CONFIG.PCW_FPGA1_PERIPHERAL_FREQMHZ {150} \
  CONFIG.PCW_USE_M_AXI_GP0 {1} \
  CONFIG.PCW_USE_M_AXI_GP1 {1} \
  CONFIG.PCW_ENET0_PERIPHERAL_ENABLE {0} \
  CONFIG.PCW_QSPI_GRP_SINGLE_SS_ENABLE {0} \
  CONFIG.PCW_SD0_PERIPHERAL_ENABLE {0} \
  CONFIG.PCW_USB0_PERIPHERAL_ENABLE {0} \
  CONFIG.PCW_QSPI_PERIPHERAL_ENABLE {0} \
  CONFIG.PCW_USE_S_AXI_HP0 {1} \
  CONFIG.PCW_USE_S_AXI_HP2 {1} \
  CONFIG.PCW_S_AXI_HP0_DATA_WIDTH {32} \
  CONFIG.PCW_S_AXI_HP2_DATA_WIDTH {32} \
  CONFIG.PCW_UIPARAM_DDR_ADV_ENABLE {1} \
  CONFIG.PCW_DDR_HPR_TO_CRITICAL_PRIORITY_LEVEL {2} \
  CONFIG.PCW_DDR_LPR_TO_CRITICAL_PRIORITY_LEVEL {15} \
  CONFIG.PCW_DDR_WRITE_TO_CRITICAL_PRIORITY_LEVEL {7} \
  CONFIG.PCW_DDR_PORT2_HPR_ENABLE {1} \
  CONFIG.PCW_DDR_PRIORITY_READPORT_2 {Medium} \
  CONFIG.PCW_DDR_PRIORITY_WRITEPORT_3 {Medium} \
  CONFIG.PCW_IRQ_F2P_INTR {1} \
  CONFIG.PCW_USE_FABRIC_INTERRUPT {1} \
] [get_bd_cells processing_system7_0]

set_property CONFIG.NUM_SI {1} [get_bd_cells smartconn_gpu_2_ddr]
set_property CONFIG.NUM_SI {1} [get_bd_cells smartconn_gp0_2_gpu]
set_property CONFIG.NUM_SI {1} [get_bd_cells smartconn_gp1_2_vdma]
set_property CONFIG.NUM_SI {1} [get_bd_cells smartconn_vdma_2_ddr]

if {$output_resolution == "640x480"} {
  puts "Create SerialClk with Clocking Wizard in case of 640x480p"
  puts "Use a lower GPU clock of 120 MHz due to a large framebuffer"
  set_property -dict [list \
    CONFIG.NUM_OUT_CLKS {2} \
    CONFIG.CLKOUT1_USED {true} \
    CONFIG.CLKOUT2_USED {true} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {25.175} \
    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {125.875} \
    CONFIG.MMCM_CLKFBOUT_MULT_F {17.625} \
    CONFIG.MMCM_CLKOUT1_DIVIDE_F {35.000} \
    CONFIG.MMCM_CLKOUT2_DIVIDE_F {7.000} \
    CONFIG.MMCM_DIVCLK_DIVIDE {2} \
    CONFIG.RESET_PORT {resetn} \
    CONFIG.RESET_TYPE {ACTIVE_LOW} \
  ] [get_bd_cells clk_wiz_0]
  set_property -dict [list \
    CONFIG.kGenerateSerialClk {false} \
  ] [get_bd_cells rgb2dvi_0]
  set_property -dict [list \
  CONFIG.PCW_FPGA1_PERIPHERAL_FREQMHZ {120}
] [get_bd_cells processing_system7_0]
} elseif {$output_resolution == "800x600"} {
  set_property -dict [list \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {40} \
    CONFIG.MMCM_CLKFBOUT_MULT_F {8.000} \
    CONFIG.MMCM_CLKOUT1_DIVIDE_F {20.000} \
    CONFIG.MMCM_DIVCLK_DIVIDE {1} \
    CONFIG.RESET_PORT {resetn} \
    CONFIG.RESET_TYPE {ACTIVE_LOW} \
  ] [get_bd_cells clk_wiz_0]
  set_property -dict [list \
    CONFIG.kClkPrimitive {MMCM} \
    CONFIG.kClkRange {3} \
  ] [get_bd_cells rgb2dvi_0]
} elseif {$output_resolution == "1280x720"} {
  set_property -dict [list \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {74.25} \
    CONFIG.MMCM_CLKFBOUT_MULT_F {14.850} \
    CONFIG.MMCM_CLKOUT1_DIVIDE_F {10.000} \
    CONFIG.MMCM_DIVCLK_DIVIDE {2} \
    CONFIG.RESET_PORT {resetn} \
    CONFIG.RESET_TYPE {ACTIVE_LOW} \
  ] [get_bd_cells clk_wiz_0]
  set_property -dict [list \
    CONFIG.kClkPrimitive {MMCM} \
    CONFIG.kClkRange {3} \
  ] [get_bd_cells rgb2dvi_0]
} elseif {$output_resolution == "1920x1080"} {
  set_property -dict [list \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {148.5} \
    CONFIG.MMCM_CLKFBOUT_MULT_F {11.880} \
    CONFIG.MMCM_CLKOUT1_DIVIDE_F {8.000} \
    CONFIG.MMCM_DIVCLK_DIVIDE {1} \
    CONFIG.RESET_PORT {resetn} \
    CONFIG.RESET_TYPE {ACTIVE_LOW} \
    CONFIG.JITTER_SEL {Min_O_Jitter} \
    CONFIG.MMCM_BANDWIDTH {HIGH} \
  ] [get_bd_cells clk_wiz_0]
  set_property -dict [list \
    CONFIG.kClkPrimitive {MMCM} \
    CONFIG.kClkRange {1} \
  ] [get_bd_cells rgb2dvi_0]
} elseif {$output_resolution == "2560x1440"} {
  set_property -dict [list \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {115.711} \
    CONFIG.MMCM_CLKFBOUT_MULT_F {11.571} \
    CONFIG.MMCM_CLKOUT1_DIVIDE_F {10.000} \
    CONFIG.MMCM_DIVCLK_DIVIDE {1} \
    CONFIG.RESET_PORT {resetn} \
    CONFIG.RESET_TYPE {ACTIVE_LOW} \
    CONFIG.JITTER_SEL {Min_O_Jitter} \
    CONFIG.MMCM_BANDWIDTH {HIGH} \
  ] [get_bd_cells clk_wiz_0]
  set_property -dict [list \
    CONFIG.kClkPrimitive {MMCM} \
    CONFIG.kClkRange {2} \
  ] [get_bd_cells rgb2dvi_0]
} elseif {$output_resolution == "3840x2160"} {
  set_property -dict [list \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {205.564} \
    CONFIG.MMCM_CLKFBOUT_MULT_F {10.280} \
    CONFIG.MMCM_CLKOUT1_DIVIDE_F {5.000} \
    CONFIG.MMCM_DIVCLK_DIVIDE {1} \
    CONFIG.RESET_PORT {resetn} \
    CONFIG.RESET_TYPE {ACTIVE_LOW} \
    CONFIG.JITTER_SEL {Min_O_Jitter} \
    CONFIG.MMCM_BANDWIDTH {HIGH} \
  ] [get_bd_cells clk_wiz_0]
  set_property -dict [list \
    CONFIG.kClkPrimitive {MMCM} \
    CONFIG.kClkRange {1} \
  ] [get_bd_cells rgb2dvi_0]
}

set_property -dict [list \
  CONFIG.FRAME_HEIGHT_SCALED [expr ${param_frame_height}/${param_frame_scaling_factor}] \
  CONFIG.FRAME_WIDTH_SCALED [expr ${param_frame_width}/${param_frame_scaling_factor}] \
  CONFIG.FBUF_ADDR_WIDTH ${param_fbuf_addr_width} \
  CONFIG.FBUF_DATA_WIDTH ${param_fbuf_data_width} \
  CONFIG.AXI_ADDRESS_WIDTH {32} \
  CONFIG.AXI_DATA_WIDTH {32} \
] [get_bd_cells axi4_lite_gpu_0]

set_property -dict [list \
  CONFIG.FRAME_HEIGHT ${param_frame_height} \
  CONFIG.CONTROL_DELAY {2} \
  CONFIG.SCALING_FACTOR ${param_frame_scaling_factor} \
  CONFIG.FBUF_ADDR_WIDTH ${param_fbuf_addr_width} \
] [get_bd_cells fbuf2rgb_0]

set_property CONFIG.SWITCH_RGB_TO_RBG {1} [get_bd_cells color_converter_0]
set_property CONFIG.kRstActiveHigh {false} [get_bd_cells rgb2dvi_0]

endgroup

connect_bd_net [get_bd_pins processing_system7_0/FCLK_RESET0_N] [get_bd_pins proc_sys_reset_0/ext_reset_in]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK1] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins clk_wiz_0/clk_in1]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK1] [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK1] [get_bd_pins processing_system7_0/M_AXI_GP1_ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK1] [get_bd_pins processing_system7_0/S_AXI_HP0_ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK1] [get_bd_pins processing_system7_0/S_AXI_HP2_ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK1] [get_bd_pins axi4_lite_gpu_0/s_axi_ctrl_aclk]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK1] [get_bd_pins axi4_lite_gpu_0/m_axi_fbuf_aclk]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK1] [get_bd_pins fbuf2rgb_0/s_axi_ctrl_aclk]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK1] [get_bd_pins fbuf2rgb_0/m_axi_fbuf_aclk]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins clk_wiz_0/resetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi4_lite_gpu_0/s_axi_ctrl_aresetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi4_lite_gpu_0/m_axi_fbuf_aresetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins fbuf2rgb_0/s_axi_ctrl_aresetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins fbuf2rgb_0/m_axi_fbuf_aresetn]
create_bd_port -dir O -from 3 -to 0 led
connect_bd_net [get_bd_ports led] [get_bd_pins block_0/out_led]
create_bd_port -dir I -from 3 -to 0 btn
connect_bd_net [get_bd_ports btn] [get_bd_pins block_0/in_btn]
create_bd_port -dir I sw0
apply_board_connection -board_interface "hdmi_out" -ip_intf "rgb2dvi_0/TMDS" -diagram "design_1"
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins block_0/clk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins rgb2dvi_0/PixelClk]
if {$output_resolution == "640x480"} {
  connect_bd_net [get_bd_pins clk_wiz_0/clk_out2] [get_bd_pins rgb2dvi_0/SerialClk]
}
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins fbuf2rgb_0/video_clk]
connect_bd_net [get_bd_pins clk_wiz_0/locked] [get_bd_pins fbuf2rgb_0/video_rst_n]
connect_bd_net [get_bd_pins clk_wiz_0/locked] [get_bd_pins rgb2dvi_0/aRst_n]
connect_bd_net [get_bd_pins color_converter_0/in_color] [get_bd_pins fbuf2rgb_0/video_pixel]
connect_bd_net [get_bd_pins color_converter_0/out_color] [get_bd_pins rgb2dvi_0/vid_pData]
connect_bd_net [get_bd_pins fbuf2rgb_0/video_hsync] [get_bd_pins rgb2dvi_0/vid_pHSync]
connect_bd_net [get_bd_pins fbuf2rgb_0/video_vsync] [get_bd_pins rgb2dvi_0/vid_pVSync]
connect_bd_net [get_bd_pins fbuf2rgb_0/video_vde] [get_bd_pins rgb2dvi_0/vid_pVDE]

connect_bd_intf_net [get_bd_intf_pins axi4_lite_gpu_0/m_axi_fbuf] [get_bd_intf_pins smartconn_gpu_2_ddr/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins smartconn_gpu_2_ddr/M00_AXI] [get_bd_intf_pins processing_system7_0/S_AXI_HP0]
connect_bd_net [get_bd_pins smartconn_gpu_2_ddr/aclk] [get_bd_pins processing_system7_0/FCLK_CLK1]
connect_bd_net [get_bd_pins smartconn_gpu_2_ddr/aresetn] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]

connect_bd_intf_net [get_bd_intf_pins processing_system7_0/M_AXI_GP0] [get_bd_intf_pins smartconn_gp0_2_gpu/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins smartconn_gp0_2_gpu/M00_AXI] [get_bd_intf_pins axi4_lite_gpu_0/s_axi_ctrl]
connect_bd_net [get_bd_pins smartconn_gp0_2_gpu/aclk] [get_bd_pins processing_system7_0/FCLK_CLK1]
connect_bd_net [get_bd_pins smartconn_gp0_2_gpu/aresetn] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]

connect_bd_intf_net [get_bd_intf_pins fbuf2rgb_0/m_axi_fbuf] [get_bd_intf_pins smartconn_vdma_2_ddr/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins smartconn_vdma_2_ddr/M00_AXI] [get_bd_intf_pins processing_system7_0/S_AXI_HP2]
connect_bd_net [get_bd_pins smartconn_vdma_2_ddr/aclk] [get_bd_pins processing_system7_0/FCLK_CLK1]
connect_bd_net [get_bd_pins smartconn_vdma_2_ddr/aresetn] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]

connect_bd_intf_net [get_bd_intf_pins processing_system7_0/M_AXI_GP1] [get_bd_intf_pins smartconn_gp1_2_vdma/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins smartconn_gp1_2_vdma/M00_AXI] [get_bd_intf_pins fbuf2rgb_0/s_axi_ctrl]
connect_bd_net [get_bd_pins smartconn_gp1_2_vdma/aclk] [get_bd_pins processing_system7_0/FCLK_CLK1]
connect_bd_net [get_bd_pins smartconn_gp1_2_vdma/aresetn] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]

assign_bd_address -target_address_space /axi4_lite_gpu_0/m_axi_fbuf [get_bd_addr_segs processing_system7_0/S_AXI_HP0/HP0_DDR_LOWOCM] -force
assign_bd_address -target_address_space /fbuf2rgb_0/m_axi_fbuf [get_bd_addr_segs processing_system7_0/S_AXI_HP2/HP2_DDR_LOWOCM] -force
assign_bd_address -target_address_space /processing_system7_0/Data [get_bd_addr_segs axi4_lite_gpu_0/s_axi_ctrl/reg0] -force
set_property range 8M [get_bd_addr_segs {processing_system7_0/Data/SEG_axi4_lite_gpu_0_reg0}]
set_property offset 0x40000000 [get_bd_addr_segs {processing_system7_0/Data/SEG_axi4_lite_gpu_0_reg0}]

regenerate_bd_layout
save_bd_design
write_bd_layout -force -format svg -verbose "${project_folder}/block_design.svg" ; # Needs GUI mode
make_wrapper -files [get_files "${project_folder}/block_design/design_1/design_1.bd"] -top
add_files -norecurse "${project_folder}/block_design/design_1/hdl/design_1_wrapper.v"
set_property top design_1_wrapper [current_fileset]
update_compile_order -fileset sources_1

set_property top tb_axi4_lite_gpu [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
