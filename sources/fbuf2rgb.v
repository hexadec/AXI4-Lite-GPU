`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.06.2025 10:18:13
// Design Name: 
// Module Name: fbuf2rgb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// Use 2x-8x upscaling (for bigger resolutions) from framebuffer to prevent memory bandwidth problems
module fbuf2rgb
#(
    parameter AXI_ADDRESS_WIDTH = 32,
    parameter AXI_DATA_WIDTH = 32,
    parameter FRAME_HEIGHT = 480,
    parameter SCALING_FACTOR = 1,
    parameter FBUF_ADDR_WIDTH = 19,
    parameter COLOR_WIDTH = 24,
    parameter CONTROL_DELAY = 2 // Compensate for pixel address calculation delay & BRAM access
) (

    // AXI global signals
    input s_axi_ctrl_aclk,
    input s_axi_ctrl_aresetn,
    // Read address channel
    input [AXI_ADDRESS_WIDTH - 1 : 0] s_axi_ctrl_araddr,
    input s_axi_ctrl_arvalid,
    output s_axi_ctrl_arready,
    // Read data channel
    output [AXI_DATA_WIDTH - 1 : 0] s_axi_ctrl_rdata,
    output [1:0] s_axi_ctrl_rresp,
    output s_axi_ctrl_rvalid,
    input s_axi_ctrl_rready,
    // Write address channel
    input [AXI_ADDRESS_WIDTH - 1 : 0] s_axi_ctrl_awaddr,
    input s_axi_ctrl_awvalid,
    output s_axi_ctrl_awready,
    // Write data channel
    input [AXI_DATA_WIDTH - 1 : 0] s_axi_ctrl_wdata,
    input s_axi_ctrl_wvalid,
    output s_axi_ctrl_wready,
    // Write response channel
    output [1:0] s_axi_ctrl_bresp,
    output s_axi_ctrl_bvalid,
    input s_axi_ctrl_bready,

    // AXI global signals
    input m_axi_fbuf_aclk,
    input m_axi_fbuf_aresetn,
    // Read address channel
    output [AXI_ADDRESS_WIDTH - 1 : 0] m_axi_fbuf_araddr,
    output m_axi_fbuf_arvalid,
    input m_axi_fbuf_arready,
    // Read data channel
    input [AXI_DATA_WIDTH - 1 : 0] m_axi_fbuf_rdata,
    input [1:0] m_axi_fbuf_rresp,
    input m_axi_fbuf_rvalid,
    output m_axi_fbuf_rready,
    // Write address channel
    output [AXI_ADDRESS_WIDTH - 1 : 0] m_axi_fbuf_awaddr,
    output m_axi_fbuf_awvalid,
    input m_axi_fbuf_awready,
    // Write data channel
    output [AXI_DATA_WIDTH - 1 : 0] m_axi_fbuf_wdata,
    output m_axi_fbuf_wvalid,
    input m_axi_fbuf_wready,
    // Write response channel
    input [1:0] m_axi_fbuf_bresp,
    input m_axi_fbuf_bvalid,
    output m_axi_fbuf_bready,


    input wire video_clk,
    input wire video_rst_n,
    output wire video_hsync,
    output wire video_vsync,
    output wire video_vde,
    output wire video_eof,
    output wire [COLOR_WIDTH - 1 : 0] video_pixel,

    output wire [FBUF_ADDR_WIDTH - 1 : 0] pixel_fbuf_address,
    output wire pixel_fbuf_address_valid,
    output wire [12:0] pixel_x,
    output wire [12:0] pixel_y
    );

    function [12:0] frame_h;
        input integer value;
        if (value == 2160) begin
            frame_h = 3840;
        end else if (value == 1440) begin
            frame_h = 2560;
        end else if (value == 1080) begin
            frame_h = 1920;
        end else if (value == 720) begin
            frame_h = 1280;
        end else if (value == 600) begin
            frame_h = 800;
        end else if (value == 480) begin
            frame_h = 640;
        end else if (value == 4) begin
            frame_h = 8;
        end else begin
            frame_h = 0;
        end
    endfunction

    function [12:0] frame_h_front_porch;
        input integer value;
        if (value == 2160) begin
            frame_h_front_porch = 8;
        end else if (value == 1440) begin
            frame_h_front_porch = 8;
        end else if (value == 1080) begin
            frame_h_front_porch = 88;
        end else if (value == 720) begin
            frame_h_front_porch = 110;
        end else if (value == 600) begin
            frame_h_front_porch = 40;
        end else if (value == 480) begin
            frame_h_front_porch = 8;
        end else if (value == 4) begin
            frame_h_front_porch = 1;
        end else begin
            frame_h_front_porch = 0;
        end
    endfunction

    function [12:0] frame_h_sync;
        input integer value;
        if (value == 2160) begin
            frame_h_sync = 32;
        end else if (value == 1440) begin
            frame_h_sync = 32;
        end else if (value == 1080) begin
            frame_h_sync = 44;
        end else if (value == 720) begin
            frame_h_sync = 40;
        end else if (value == 600) begin
            frame_h_sync = 128;
        end else if (value == 480) begin
            frame_h_sync = 96;
        end else if (value == 4) begin
            frame_h_sync = 2;
        end else begin
            frame_h_sync = 0;
        end
    endfunction

    function [12:0] frame_h_back_porch;
        input integer value;
        if (value == 2160) begin
            frame_h_back_porch = 40;
        end else if (value == 1440) begin
            frame_h_back_porch = 40;
        end else if (value == 1080) begin
            frame_h_back_porch = 148;
        end else if (value == 720) begin
            frame_h_back_porch = 220;
        end else if (value == 600) begin
            frame_h_back_porch = 88;
        end else if (value == 480) begin
            frame_h_back_porch = 40;
        end else if (value == 4) begin
            frame_h_back_porch = 1;
        end else begin
            frame_h_back_porch = 0;
        end
    endfunction


    function [12:0] frame_v;
        input integer value;
        if (value == 2160) begin
            frame_v = 2160;
        end else if (value == 1440) begin
            frame_v = 1440;
        end else if (value == 1080) begin
            frame_v = 1080;
        end else if (value == 720) begin
            frame_v = 720;
        end else if (value == 600) begin
            frame_v = 600;
        end else if (value == 480) begin
            frame_v = 480;
        end else if (value == 4) begin
            frame_v = 4;
        end else begin
            frame_v = 0;
        end
    endfunction

    function [12:0] frame_v_front_porch;
        input integer value;
        if (value == 2160) begin
            frame_v_front_porch = 11;
        end else if (value == 1440) begin
            frame_v_front_porch = 7;
        end else if (value == 1080) begin
            frame_v_front_porch = 4;
        end else if (value == 720) begin
            frame_v_front_porch = 5;
        end else if (value == 600) begin
            frame_v_front_porch = 1;
        end else if (value == 480) begin
            frame_v_front_porch = 2;
        end else if (value == 4) begin
            frame_v_front_porch = 1;
        end else begin
            frame_v_front_porch = 0;
        end
    endfunction

    function [12:0] frame_v_sync;
        input integer value;
        if (value == 2160) begin
            frame_v_sync = 8;
        end else if (value == 1440) begin
            frame_v_sync = 8;
        end else if (value == 1080) begin
            frame_v_sync = 5;
        end else if (value == 720) begin
            frame_v_sync = 5;
        end else if (value == 600) begin
            frame_v_sync = 4;
        end else if (value == 480) begin
            frame_v_sync = 2;
        end else if (value == 4) begin
            frame_v_sync = 2;
        end else begin
            frame_v_sync = 0;
        end
    endfunction

    function [12:0] frame_v_back_porch;
        input integer value;
        if (value == 2160) begin
            frame_v_back_porch = 6;
        end else if (value == 1440) begin
            frame_v_back_porch = 6;
        end else if (value == 1080) begin
            frame_v_back_porch = 36;
        end else if (value == 720) begin
            frame_v_back_porch = 20;
        end else if (value == 600) begin
            frame_v_back_porch = 23;
        end else if (value == 480) begin
            frame_v_back_porch = 25;
        end else if (value == 4) begin
            frame_v_back_porch = 1;
        end else begin
            frame_v_back_porch = 0;
        end
    endfunction


    function reg h_sync_active_low;
        input integer value;
        if (value == 2160) begin
            h_sync_active_low = 0;
        end else if (value == 1440) begin
            h_sync_active_low = 0;
        end else if (value == 1080) begin
            h_sync_active_low = 0;
        end else if (value == 720) begin
            h_sync_active_low = 0;
        end else if (value == 600) begin
            h_sync_active_low = 0;
        end else if (value == 480) begin
            h_sync_active_low = 0;
        end else if (value == 4) begin
            h_sync_active_low = 0;
        end else begin
            h_sync_active_low = 0;
        end
    endfunction

    function reg v_sync_active_low;
        input integer value;
        if (value == 2160) begin
            v_sync_active_low = 1;
        end else if (value == 1440) begin
            v_sync_active_low = 1;
        end else if (value == 1080) begin
            v_sync_active_low = 0;
        end else if (value == 720) begin
            v_sync_active_low = 0;
        end else if (value == 600) begin
            v_sync_active_low = 0;
        end else if (value == 480) begin
            v_sync_active_low = 0;
        end else if (value == 4) begin
            v_sync_active_low = 0;
        end else begin
            v_sync_active_low = 0;
        end
    endfunction

    localparam FRAME_H = frame_h(FRAME_HEIGHT);
    localparam FRAME_H_FRONT_PORCH = frame_h_front_porch(FRAME_HEIGHT);
    localparam FRAME_H_SYNC = frame_h_sync(FRAME_HEIGHT);
    localparam FRAME_H_BACK_PORCH = frame_h_back_porch(FRAME_HEIGHT);
    localparam FRAME_V = frame_v(FRAME_HEIGHT);
    localparam FRAME_V_FRONT_PORCH = frame_v_front_porch(FRAME_HEIGHT);
    localparam FRAME_V_SYNC = frame_v_sync(FRAME_HEIGHT);
    localparam FRAME_V_BACK_PORCH = frame_v_back_porch(FRAME_HEIGHT);
    localparam H_SYNC_ACTIVE_LOW = h_sync_active_low(FRAME_HEIGHT);
    localparam V_SYNC_ACTIVE_LOW = v_sync_active_low(FRAME_HEIGHT);
    
    localparam FRAME_H_TOTAL = FRAME_H + FRAME_H_FRONT_PORCH + FRAME_H_SYNC + FRAME_H_BACK_PORCH;
    localparam FRAME_V_TOTAL = FRAME_V + FRAME_V_FRONT_PORCH + FRAME_V_SYNC + FRAME_V_BACK_PORCH;
    
    localparam FRAME_H_SYNC_START = FRAME_H + FRAME_H_FRONT_PORCH;
    localparam FRAME_V_SYNC_START = FRAME_V + FRAME_V_FRONT_PORCH;
    
    localparam FRAME_H_SYNC_END = FRAME_H + FRAME_H_FRONT_PORCH + FRAME_H_SYNC;
    localparam FRAME_V_SYNC_END = FRAME_V + FRAME_V_FRONT_PORCH + FRAME_V_SYNC;
    
    // TODO: add gray coded counters for CDC fault tolerance
    reg [12:0] h_counter;
    reg [12:0] v_counter;

    reg [COLOR_WIDTH - 1 : 0] line1_buffer [FRAME_V / SCALING_FACTOR - 1 : 0];
    reg [COLOR_WIDTH - 1 : 0] line2_buffer [FRAME_V / SCALING_FACTOR - 1 : 0];
    
    always @(posedge video_clk) begin
        if (!video_rst_n) begin
            h_counter <= 0;
            v_counter <= 0;
        end else if (h_counter == FRAME_H_TOTAL - 1) begin
            h_counter <= 0;
            if (v_counter == FRAME_V_TOTAL - 1) begin
                v_counter <= 0;
            end else begin
                v_counter <= v_counter + 1;
            end
        end else begin
            h_counter <= h_counter + 1;
        end
    end
    
    reg [CONTROL_DELAY : 0] vde_int;
    reg [CONTROL_DELAY : 0] eof_int;
    reg [CONTROL_DELAY : 0] hsync_int;
    reg [CONTROL_DELAY : 0] vsync_int;
    reg [COLOR_WIDTH - 1 : 0] pixel_int;
    reg [12:0] pixel_x_int [CONTROL_DELAY : 0];
    reg [12:0] pixel_y_int [CONTROL_DELAY : 0];
    reg [FBUF_ADDR_WIDTH - 1 : 0] pixel_fbuf_address_int;
    reg pixel_fbuf_address_valid_int;
    
    assign vde_int_0 = h_counter < FRAME_H && v_counter < FRAME_V;
    
    integer i;
    integer j;
    always @(posedge video_clk) begin
        if (!video_rst_n) begin
            vde_int <= 0;
            eof_int <= 0;
            hsync_int <= 0;
            vsync_int <= 0;
            pixel_int <= 0;
            pixel_fbuf_address_int <= 0;
            pixel_fbuf_address_valid_int <= 0;
            for (i = 0; i < CONTROL_DELAY + 1; i = i + 1) begin
                pixel_x_int[i] <= 0;
                pixel_y_int[i] <= 0;
            end
        end else begin
            //$display("H: %d, V: %d, VDE_INT: %b, HSYNC_INT: %b, VSYNC_INT: %b, EOF_INT: %b, ADDR_INT: %d", h_counter, v_counter, vde_int, hsync_int, vsync_int, eof_int, pixel_fbuf_address_int);
            //$display("ADDR_H_COMP: %d, ADDR_V_COMP: %d",  (h_counter / SCALING_FACTOR), (v_counter / SCALING_FACTOR) * FRAME_H / SCALING_FACTOR);
            vde_int <= {vde_int[CONTROL_DELAY - 1 : 0], vde_int_0};
            eof_int <= {eof_int[CONTROL_DELAY - 1 : 0], v_counter >= FRAME_V};
            hsync_int <= {hsync_int[CONTROL_DELAY - 1 : 0], H_SYNC_ACTIVE_LOW ^ (h_counter >= FRAME_H_SYNC_START && h_counter < FRAME_H_SYNC_END)};
            vsync_int <= {vsync_int[CONTROL_DELAY - 1 : 0], V_SYNC_ACTIVE_LOW ^ (v_counter >= FRAME_V_SYNC_START && v_counter < FRAME_V_SYNC_END)};
            pixel_x_int[0] <= vde_int_0 ? h_counter : 0;
            pixel_y_int[0] <= vde_int_0 ? v_counter : 0;
            for (j = 1; j < CONTROL_DELAY + 1; j = j + 1) begin
                pixel_x_int[j] <= pixel_x_int[j - 1];
                pixel_y_int[j] <= pixel_y_int[j - 1];
            end

            if (v_counter % 2 == 0) begin
                pixel_int <= line1_buffer[h_counter / SCALING_FACTOR];
            end else begin
                pixel_int <= line2_buffer[h_counter / SCALING_FACTOR];
            end

            pixel_fbuf_address_int <= vde_int_0 ? (v_counter / SCALING_FACTOR) * FRAME_H / SCALING_FACTOR + (h_counter / SCALING_FACTOR) : 0;
            pixel_fbuf_address_valid_int <= vde_int_0;
        end
    end
    
    assign video_vde = !video_rst_n ? 0 : vde_int[CONTROL_DELAY];
    assign video_eof = !video_rst_n ? 0 : eof_int[CONTROL_DELAY];
    assign video_hsync = !video_rst_n ? 0 : hsync_int[CONTROL_DELAY];
    assign video_vsync = !video_rst_n ? 0 : vsync_int[CONTROL_DELAY];
    assign video_pixel = pixel_int;
    
    assign pixel_x = !video_rst_n ? 13'b0 : pixel_x_int[CONTROL_DELAY];
    assign pixel_y = !video_rst_n ? 13'b0 : pixel_y_int[CONTROL_DELAY];

    assign pixel_fbuf_address = !video_rst_n ? 24'b0 : pixel_fbuf_address_int;
    assign pixel_fbuf_address_valid = !video_rst_n ? 0 : pixel_fbuf_address_valid_int;


    // AXI framebuffer reader signals

    assign m_axi_fbuf_awaddr = 0;
    assign m_axi_fbuf_awvalid = 0;
    assign m_axi_fbuf_wdata = 0;
    assign m_axi_fbuf_wvalid = 0;
    assign m_axi_fbuf_bready = 0;
    
endmodule
