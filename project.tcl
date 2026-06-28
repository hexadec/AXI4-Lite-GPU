set output_resolution "1920x1080"

if {$output_resolution == "640x480"} {
  # 60 Hz
  set param_fbuf_addr_width 19;
  set param_fbuf_data_width 8;
  set param_frame_scaling_factor 1;
  set param_frame_width 640;
  set param_frame_height 480;
} elseif {$output_resolution == "800x600"} {
  # 60 Hz
  set param_fbuf_addr_width 17;
  set param_fbuf_data_width 8;
  set param_frame_scaling_factor 2;
  set param_frame_width 800;
  set param_frame_height 600;
} elseif {$output_resolution == "1280x720"} {
  # 60 Hz
  set param_fbuf_addr_width 18;
  set param_fbuf_data_width 8;
  set param_frame_scaling_factor 2;
  set param_frame_width 1280;
  set param_frame_height 720;
} elseif {$output_resolution == "1920x1080"} {
  # 60 Hz
  set param_fbuf_addr_width 17;
  set param_fbuf_data_width 8;
  set param_frame_scaling_factor 4;
  set param_frame_width 1920;
  set param_frame_height 1080;
} elseif {$output_resolution == "2560x1440"} {
  # 30 Hz
  set param_fbuf_addr_width 18;
  set param_fbuf_data_width 8;
  set param_frame_scaling_factor 4;
  set param_frame_width 2560;
  set param_frame_height 1440;
} elseif {$output_resolution == "3840x2160"} {
  # 24 Hz
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
add_files -fileset sources_1 "${project_folder}/sources/fbuf2rgb_axi_conf.sv"
add_files -fileset sources_1 "${project_folder}/sources/fbuf2rgb_line_buffer_writer.sv"
add_files -fileset sources_1 "${project_folder}/sources/bram_to_axi4_lite_dma.sv"
add_files -fileset sources_1 "${project_folder}/sources/color_converter.v"
add_files -fileset sources_1 "${project_folder}/sources/axi4_lite_gpu.v"
add_files -fileset sources_1 "${project_folder}/sources/axi4_lite_gpu_ring_buffer.sv"
add_files -fileset sources_1 "${project_folder}/sources/axi4_lite_gpu_decode.sv"
add_files -fileset sources_1 "${project_folder}/sources/axi4_lite_gpu_execute_rect.sv"
add_files -fileset sources_1 "${project_folder}/sources/axi4_lite_gpu_execute_tri.sv"
add_files -fileset sources_1 "${project_folder}/sources/axi4_lite_gpu_execute_cir.sv"
add_files -fileset sources_1 "${project_folder}/sources/axi4_lite_gpu_execute_line.sv"
add_files -fileset sources_1 "${project_folder}/sources/axi4_lite_gpu_execute_char.sv"
add_files -fileset sources_1 "${project_folder}/sources/axi4_lite_gpu_char_rom.sv"
update_compile_order -fileset sources_1
file mkdir "${project_folder}/block_design"
create_bd_design -dir "${project_folder}/block_design" design_1
update_compile_order -fileset sources_1

set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 "${project_folder}/testbench/tb_color_converter.sv"
add_files -fileset sim_1 "${project_folder}/testbench/tb_fbuf2rgb.sv"
add_files -fileset sim_1 "${project_folder}/testbench/tb_fbuf2rgb_line_buffer_writer.sv"
add_files -fileset sim_1 "${project_folder}/testbench/tb_axi4_lite_gpu.sv"
add_files -fileset sim_1 "${project_folder}/testbench/tb_axi4_lite_gpu_ring_buffer.sv"
add_files -fileset sim_1 "${project_folder}/testbench/tb_axi4_lite_gpu_execute_rect.sv"
add_files -fileset sim_1 "${project_folder}/testbench/tb_axi4_lite_gpu_execute_tri.sv"
add_files -fileset sim_1 "${project_folder}/testbench/tb_axi4_lite_gpu_execute_cir.sv"
add_files -fileset sim_1 "${project_folder}/testbench/tb_axi4_lite_gpu_execute_line.sv"
add_files -fileset sim_1 "${project_folder}/testbench/tb_axi4_lite_gpu_execute_char.sv"
add_files -fileset sim_1 "${project_folder}/testbench/tb_axi4_lite_gpu_char_rom.sv"
add_files -fileset sim_1 "${project_folder}/testbench/tb_bram_to_axi4_lite_dma.sv"
update_compile_order -fileset sim_1

add_files -norecurse "${project_folder}/mem/font.mem"

set_property ip_repo_paths "${project_folder}/vivado-library" [current_project]
update_ip_catalog

regenerate_bd_layout
save_bd_design
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
