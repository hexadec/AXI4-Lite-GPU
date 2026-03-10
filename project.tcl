set output_resolution "1920x1080"

if {$output_resolution == "640x480"} {
  set param_fbuf_addr_width 19;
  set param_fbuf_data_width 8;
  set param_frame_scaling_factor 1;
  set param_frame_width 640;
  set param_frame_height 480;
} elseif {$output_resolution == "800x600"} {
  set param_fbuf_addr_width 17;
  set param_fbuf_data_width 8;
  set param_frame_scaling_factor 2;
  set param_frame_width 800;
  set param_frame_height 600;
} elseif {$output_resolution == "1280x720"} {
  set param_fbuf_addr_width 18;
  set param_fbuf_data_width 8;
  set param_frame_scaling_factor 2;
  set param_frame_width 1280;
  set param_frame_height 720;
} elseif {$output_resolution == "1920x1080"} {
  set param_fbuf_addr_width 17;
  set param_fbuf_data_width 8;
  set param_frame_scaling_factor 4;
  set param_frame_width 1920;
  set param_frame_height 1080;
} elseif {$output_resolution == "2560x1440"} {
  set param_fbuf_addr_width 18;
  set param_fbuf_data_width 8;
  set param_frame_scaling_factor 4;
  set param_frame_width 2560;
  set param_frame_height 1440;
} elseif {$output_resolution == "3840x2160"} {
  set param_fbuf_addr_width 17;
  set param_fbuf_data_width 8;
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

set_param board.repoPaths [list "${project_folder}/board_files"]

create_project $project_name $project_folder -part xc7z020clg400-1
set_property board_part tul.com.tw:pynq-z2:part0:1.0 [current_project]
create_fileset -constrset constraints

add_files -fileset constraints "${project_folder}/constraints/constraints.xdc"
set_property constrset constraints [get_runs synth_1]
set_property constrset constraints [get_runs impl_1]


add_files -fileset sources_1 "${project_folder}/sources/block.v"
add_files -fileset sources_1 "${project_folder}/sources/btn_debounce.v"
add_files -fileset sources_1 "${project_folder}/sources/fbuf2rgb.v"
add_files -fileset sources_1 "${project_folder}/sources/framebuffer.sv"
add_files -fileset sources_1 "${project_folder}/sources/framebuffer_with_reset.v"
add_files -fileset sources_1 "${project_folder}/sources/framebuffer_mux.v"
add_files -fileset sources_1 "${project_folder}/sources/color_converter.v"
add_files -fileset sources_1 "${project_folder}/sources/test_pattern_generator.v"
add_files -fileset sources_1 "${project_folder}/sources/axi4_lite_gpu.v"
add_files -fileset sources_1 "${project_folder}/sources/axi4_lite_gpu_ring_buffer.sv"
add_files -fileset sources_1 "${project_folder}/sources/axi4_lite_gpu_decode.sv"
add_files -fileset sources_1 "${project_folder}/sources/axi4_lite_gpu_execute_rect.sv"
add_files -fileset sources_1 "${project_folder}/sources/axi4_lite_gpu_execute_tri.sv"
add_files -fileset sources_1 "${project_folder}/sources/axi4_lite_gpu_execute_cir.sv"
add_files -fileset sources_1 "${project_folder}/sources/axi4_lite_gpu_execute_line.sv"
update_compile_order -fileset sources_1
file mkdir "${project_folder}/block_design"
create_bd_design -dir "${project_folder}/block_design" design_1
update_compile_order -fileset sources_1

set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 "${project_folder}/testbench/tb_color_converter.sv"
add_files -fileset sim_1 "${project_folder}/testbench/tb_fbuf2rgb.sv"
add_files -fileset sim_1 "${project_folder}/testbench/tb_axi4_lite_gpu.sv"
add_files -fileset sim_1 "${project_folder}/testbench/tb_axi4_lite_gpu_ring_buffer.sv"
add_files -fileset sim_1 "${project_folder}/testbench/tb_axi4_lite_gpu_execute_rect.sv"
add_files -fileset sim_1 "${project_folder}/testbench/tb_axi4_lite_gpu_execute_tri.sv"
add_files -fileset sim_1 "${project_folder}/testbench/tb_axi4_lite_gpu_execute_cir.sv"
add_files -fileset sim_1 "${project_folder}/testbench/tb_axi4_lite_gpu_execute_line.sv"
add_files -fileset sim_1 "${project_folder}/testbench/tb_framebuffer.sv"
update_compile_order -fileset sim_1

set_property ip_repo_paths "${project_folder}/vivado-library" [current_project]
update_ip_catalog

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
create_bd_cell -type module -reference btn_debounce mux_sel_debounce_0
create_bd_cell -type module -reference framebuffer_with_reset framebuffer_0
create_bd_cell -type module -reference framebuffer_mux framebuffer_mux_0
create_bd_cell -type module -reference fbuf2rgb fbuf2rgb_0
create_bd_cell -type module -reference color_converter color_converter_0
create_bd_cell -type module -reference test_pattern_generator test_pattern_generat_0
create_bd_cell -type module -reference axi4_lite_gpu axi4_lite_gpu_0

set_property -dict [list \
  CONFIG.PCW_APU_PERIPHERAL_FREQMHZ {300} \
  CONFIG.PCW_UIPARAM_DDR_FREQ_MHZ {400} \
  CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} \
  CONFIG.PCW_EN_CLK1_PORT {1} \
  CONFIG.PCW_FPGA1_PERIPHERAL_FREQMHZ {140} \
  CONFIG.PCW_USE_M_AXI_GP0 {1} \
  CONFIG.PCW_ENET0_PERIPHERAL_ENABLE {0} \
  CONFIG.PCW_QSPI_GRP_SINGLE_SS_ENABLE {0} \
  CONFIG.PCW_SD0_PERIPHERAL_ENABLE {0} \
  CONFIG.PCW_USB0_PERIPHERAL_ENABLE {0} \
  CONFIG.PCW_QSPI_PERIPHERAL_ENABLE {0} \
] [get_bd_cells processing_system7_0]

if {$output_resolution == "640x480"} {
  set_property -dict [list \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {25.175} \
    CONFIG.MMCM_CLKFBOUT_MULT_F {8.000} \
    CONFIG.MMCM_CLKOUT1_DIVIDE_F {31.750} \
    CONFIG.MMCM_DIVCLK_DIVIDE {1} \
    CONFIG.RESET_PORT {resetn} \
    CONFIG.RESET_TYPE {ACTIVE_LOW} \
  ] [get_bd_cells clk_wiz_0]
  set_property -dict [list \
    CONFIG.kClkPrimitive {MMCM} \
    CONFIG.kClkRange {3} \
  ] [get_bd_cells rgb2dvi_0]
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
  CONFIG.ADDR_WIDTH ${param_fbuf_addr_width} \
  CONFIG.DATA_WIDTH ${param_fbuf_data_width} \
  CONFIG.FRAME_HEIGHT ${param_frame_height} \
  CONFIG.FRAME_WIDTH ${param_frame_width} \
  CONFIG.SCALING_FACTOR ${param_frame_scaling_factor} \
] [get_bd_cells framebuffer_0]

set_property -dict [list \
  CONFIG.FBUF_ADDR_WIDTH ${param_fbuf_addr_width} \
  CONFIG.FBUF_DATA_WIDTH ${param_fbuf_data_width} \
] [get_bd_cells framebuffer_mux_0]

set_property -dict [list \
  CONFIG.FRAME_HEIGHT ${param_frame_height} \
  CONFIG.FRAME_WIDTH ${param_frame_width} \
  CONFIG.SCALING_FACTOR ${param_frame_scaling_factor} \
  CONFIG.FBUF_ADDR_WIDTH ${param_fbuf_addr_width} \
] [get_bd_cells test_pattern_generat_0]

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

set_property CONFIG.FBUF_DATA_WIDTH ${param_fbuf_data_width} [get_bd_cells color_converter_0]

set_property CONFIG.kRstActiveHigh {false} [get_bd_cells rgb2dvi_0]

endgroup

connect_bd_net [get_bd_pins processing_system7_0/FCLK_RESET0_N] [get_bd_pins proc_sys_reset_0/ext_reset_in]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK1] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins clk_wiz_0/clk_in1]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK1] [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK1] [get_bd_pins test_pattern_generat_0/clk]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK1] [get_bd_pins framebuffer_0/clk_wr]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK1] [get_bd_pins axi4_lite_gpu_0/s_axi_ctrl_aclk]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK1] [get_bd_pins mux_sel_debounce_0/clk]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins clk_wiz_0/resetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins test_pattern_generat_0/rst_n]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi4_lite_gpu_0/s_axi_ctrl_aresetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins mux_sel_debounce_0/rst_n]
create_bd_port -dir O -from 3 -to 0 led
connect_bd_net [get_bd_ports led] [get_bd_pins block_0/out_led]
create_bd_port -dir I -from 3 -to 0 btn
connect_bd_net [get_bd_ports btn] [get_bd_pins block_0/in_btn]
create_bd_port -dir I sw0
connect_bd_net [get_bd_ports sw0] [get_bd_pins mux_sel_debounce_0/btn_in]
apply_board_connection -board_interface "hdmi_out" -ip_intf "rgb2dvi_0/TMDS" -diagram "design_1"
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins block_0/clk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins rgb2dvi_0/PixelClk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins framebuffer_0/clk_rd]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins fbuf2rgb_0/clk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins color_converter_0/clk]
connect_bd_net [get_bd_pins clk_wiz_0/locked] [get_bd_pins fbuf2rgb_0/rst_n]
connect_bd_net [get_bd_pins clk_wiz_0/locked] [get_bd_pins rgb2dvi_0/aRst_n]
connect_bd_net [get_bd_pins axi4_lite_gpu_0/fbuf_en_wr] [get_bd_pins framebuffer_mux_0/ch0_fbuf_en_wr]
connect_bd_net [get_bd_pins axi4_lite_gpu_0/fbuf_wrea] [get_bd_pins framebuffer_mux_0/ch0_fbuf_wrea]
connect_bd_net [get_bd_pins axi4_lite_gpu_0/fbuf_addr] [get_bd_pins framebuffer_mux_0/ch0_fbuf_addr]
connect_bd_net [get_bd_pins axi4_lite_gpu_0/fbuf_data] [get_bd_pins framebuffer_mux_0/ch0_fbuf_data]
connect_bd_net [get_bd_pins axi4_lite_gpu_0/fbuf_rst_req_n] [get_bd_pins framebuffer_mux_0/ch0_fbuf_rst_req_n]
connect_bd_net [get_bd_pins test_pattern_generat_0/pixel_fbuf_wr_en] [get_bd_pins framebuffer_mux_0/ch1_fbuf_en_wr]
connect_bd_net [get_bd_pins test_pattern_generat_0/pixel_fbuf_wr_en] [get_bd_pins framebuffer_mux_0/ch1_fbuf_wrea]
connect_bd_net [get_bd_pins test_pattern_generat_0/pixel_fbuf_address] [get_bd_pins framebuffer_mux_0/ch1_fbuf_addr]
connect_bd_net [get_bd_pins test_pattern_generat_0/pixel_fbuf_color] [get_bd_pins framebuffer_mux_0/ch1_fbuf_data]
connect_bd_net [get_bd_pins test_pattern_generat_0/pixel_fbuf_rst_req_n] [get_bd_pins framebuffer_mux_0/ch1_fbuf_rst_req_n]
connect_bd_net [get_bd_pins mux_sel_debounce_0/btn_out] [get_bd_pins framebuffer_mux_0/sel]
connect_bd_net [get_bd_pins framebuffer_mux_0/fbuf_en_wr] [get_bd_pins framebuffer_0/en_wr]
connect_bd_net [get_bd_pins framebuffer_mux_0/fbuf_wrea] [get_bd_pins framebuffer_0/wrea]
connect_bd_net [get_bd_pins framebuffer_mux_0/fbuf_addr] [get_bd_pins framebuffer_0/addr_wr]
connect_bd_net [get_bd_pins framebuffer_mux_0/fbuf_data] [get_bd_pins framebuffer_0/din]
connect_bd_net [get_bd_pins framebuffer_mux_0/fbuf_rst_req_n] [get_bd_pins framebuffer_0/rst_req_n]
connect_bd_net [get_bd_pins framebuffer_0/dout] [get_bd_pins color_converter_0/in_color]
connect_bd_net [get_bd_pins framebuffer_0/rst_busy] [get_bd_pins axi4_lite_gpu_0/fbuf_rst_busy]
connect_bd_net [get_bd_pins color_converter_0/out_color] [get_bd_pins rgb2dvi_0/vid_pData]
connect_bd_net [get_bd_pins fbuf2rgb_0/hsync] [get_bd_pins rgb2dvi_0/vid_pHSync]
connect_bd_net [get_bd_pins fbuf2rgb_0/vsync] [get_bd_pins rgb2dvi_0/vid_pVSync]
connect_bd_net [get_bd_pins fbuf2rgb_0/vde] [get_bd_pins rgb2dvi_0/vid_pVDE]
connect_bd_net [get_bd_pins fbuf2rgb_0/pixel_fbuf_address] [get_bd_pins framebuffer_0/addr_rd]
connect_bd_net [get_bd_pins fbuf2rgb_0/pixel_fbuf_address_valid] [get_bd_pins framebuffer_0/en_rd]

apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { \
  Clk_master { /processing_system7_0/FCLK_CLK1} \
  Clk_slave {/processing_system7_0/FCLK_CLK1} \
  Clk_xbar {/processing_system7_0/FCLK_CLK1} \
  Master {/processing_system7_0/M_AXI_GP0} \
  Slave {/axi4_lite_gpu_0/s_axi_ctrl} \
  ddr_seg {Auto} \
  intc_ip {New AXI SmartConnect} \
  master_apm {0}\
}  [get_bd_intf_pins axi4_lite_gpu_0/s_axi_ctrl]

set_property offset 0x40000000 [get_bd_addr_segs {processing_system7_0/Data/SEG_axi4_lite_gpu_0_reg0}]
set_property range 8M [get_bd_addr_segs {processing_system7_0/Data/SEG_axi4_lite_gpu_0_reg0}]

regenerate_bd_layout
save_bd_design
write_bd_layout -force -format svg -verbose "${project_folder}/block_design.svg" ; # Needs GUI mode
make_wrapper -files [get_files "${project_folder}/block_design/design_1/design_1.bd"] -top
add_files -norecurse "${project_folder}/block_design/design_1/hdl/design_1_wrapper.v"
set_property top design_1_wrapper [current_fileset]
update_compile_order -fileset sources_1

create_run synthesis1 -flow {Vivado Synthesis 2025}
set_property AUTO_INCREMENTAL_CHECKPOINT 1 [get_runs synthesis1]
set_property AUTO_INCREMENTAL_CHECKPOINT.DIRECTORY "${project_folder}/${project_name}.srcs/utils_1/imports/synthesis1" [get_runs synthesis1]
create_run implementation1 -parent_run synthesis1 -flow {Vivado Implementation 2025}
set_property AUTO_INCREMENTAL_CHECKPOINT 1 [get_runs implementation1]
set_property AUTO_INCREMENTAL_CHECKPOINT.DIRECTORY "${project_folder}/${project_name}.srcs/utils_1/imports/implementation1" [get_runs implementation1]
current_run [get_runs synthesis1]
