set script_location [file normalize [info script]]
set project_folder [file dirname $script_location]
set project_folder_split [split $project_folder /]
set project_name [lindex $project_folder_split end]
puts "Project folder: ${project_folder}"
puts "Project name: ${project_name}"
open_project ${project_folder}/${project_name}.xpr
update_compile_order -fileset sources_1
set props [list_property [get_runs implementation1]]
foreach prop $props {
    set value [get_property $prop [get_runs implementation1]]
    puts "$prop: $value"
}

set_msg_config -id [41-2383] -new_severity ERROR; # Width mismatch when connecting input pin
set_msg_config -id [41-758] -new_severity ERROR; # The following clock pins are not connected to a valid clock source
set_msg_config -id [8-689] -new_severity ERROR; # Width of port connection does not match port width of module

reset_run synthesis1
reset_run implementation1
launch_runs implementation1 -to_step write_bitstream -jobs 4
wait_on_runs implementation1
set run_progress [get_property PROGRESS [get_runs implementation1]]
puts "Run progress: ${run_progress}"
if {${run_progress} != "100%"} {
   error "ERROR: implementation1 failed"
}
open_run implementation1
puts "========================================"
puts "\n\UTILIZATION REPORT\n\n"
puts "========================================"
report_utilization -hierarchical_min_primitive_count 50 -name utilization_1 -file reports/utilization.txt
puts "========================================"
puts "\n\nTIMING REPORT\n\n"
puts "========================================"
report_timing -nworst 5 -path_type full -input_pins -file reports/timing.txt
write_hw_platform -fixed -include_bit -force -file ${project_folder}/design_1_wrapper.xsa
