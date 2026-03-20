# AXI4-Lite GPU

This is a very simple 2D GPU, intended to help me learn logic design. Currently this project only supports the Pynq-Z2 development board, with Zynq-7020. Languages used: Verilog and SystemVerilog.

## Features
- Draw single pixel
- Draw line
- Draw filled rectangle
- Draw filled circle
- Draw filled triangle
- Timing constraints met at 150 MHz on -1 speed grade (120 MHz @ 640x480)
- 640x480@60Hz -> 4K@24Hz with 1-8x linear upscaling
- Build and program board with make
- Support programming SoC in JTAG cascade and independent mode
- Configure project from project.tcl

## Planned features
- Draw characters (using a simple 8x16 font)
- Draw ellipses / rounded rectanges
- Double buffering
- Improve pipelining
- Linux driver
- Automatic testbenches

## How-to build on Linux

### Preparation

Edit the `vivado_folder` variable in `Makefile` to point to the `bin` folder of your Vivado installation. By default it points to `~/Software/AMD/2025.2/Vivado/bin`.

### Create the project to open in Vivado

Run `make` in the project directory

### Create bitstream

Run `make bitstream` in the project directory. In the reports directory a timing and utilization report will be created as well.

### Program board

**JTAG cascade mode**

If the boot mode jumper on your Pynq-Z2 board is at the top row in JTAG position (next to SD and QSPI): Run `make ps7_program` after the bitstream is ready. To clean up temporary files created by XSDB run `make ps7_clean`.

**JTAG independent mode**

If the boot mode jumper is at the bottom row in JTAG position (next to PLL): Run `make program` after the bitstream is ready.

In both cases, the programming of the Processing System 7 is not currently supported and needs to be done separately via Vitis. Therefore, only the test pattern generator can be tested by switching SW[0] to the correct position.

### Setting the output resolution

The list of supported resolutions can be seen in the project.tcl file. Set the `output_resolution` variable to a supported value and run all steps from the beginning, including project (.xpr file) creation.

## License

*All rights reserved - 2026*
