project_name := $(shell basename $(shell pwd))
vivado_folder := ~/Software/AMD/2025.2/Vivado/bin

all: clean $(project_name).xpr

$(project_name).xpr: project.tcl
	@echo Building with Vivado...
	${vivado_folder}/vivado -mode batch -source project.tcl -verbose

bitstream: $(project_name).runs/implementation1/design_1_wrapper.bit;

$(project_name).runs/implementation1/design_1_wrapper.bit: $(project_name).xpr bitstream.tcl
	@echo Building with Vivado...
	${vivado_folder}/vivado -mode batch -source bitstream.tcl -verbose

simulate: $(project_name).xpr simulate.tcl
	${vivado_folder}/vivado -mode batch -source simulate.tcl -verbose

program: program_device.tcl
	test -f $(project_name).runs/implementation1/design_1_wrapper.bit
	${vivado_folder}/vivado -mode batch -source program_device.tcl -verbose

ps7_program: program_ps7.tcl
	${vivado_folder}/xsdb program_ps7.tcl

ps7_clean:
	rm -rf ps7_init*
    
clean:
	@echo Removing generated files from project folder
	rm -rf ${project_name}.cache ${project_name}.gen ${project_name}.hw ${project_name}.srcs
	rm -rf ${project_name}.ip_user_files ${project_name}.runs ${project_name}.sim
	rm -rf block_design .Xil NA
	rm -f *.xsa *.bit ps7_init* xvlog.pb
	rm -f ${project_name}.xpr
	rm -f vivado*.log vivado*.jou
