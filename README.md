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

## License

*All rights reserved - 2026*
