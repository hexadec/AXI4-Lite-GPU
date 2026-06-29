module fbuf2rgb_axi_dma
#(
    parameter AXI_ADDRESS_WIDTH = 32,
    parameter AXI_DATA_WIDTH = 32,
    parameter COLOR_WIDTH = 8
) (
    // AXI global signals
    input m_axi_fbuf_aclk,
    input m_axi_fbuf_aresetn,
    // Read address channel
    output [AXI_ADDRESS_WIDTH - 1 : 0] m_axi_fbuf_araddr,
    output [7:0] m_axi_fbuf_arlen,
    output [2:0] m_axi_fbuf_arsize,
    output [1:0] m_axi_fbuf_arburst,
    output m_axi_fbuf_arvalid,
    input m_axi_fbuf_arready,
    // Read data channel
    input [AXI_DATA_WIDTH - 1 : 0] m_axi_fbuf_rdata,
    input [1:0] m_axi_fbuf_rresp,
    input m_axi_fbuf_rlast,
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

    // Control signals from fbuf2rgb_line_buffer_writer
    input wire [31:0] framebuffer_offset_addr,
    input wire [15:0] framebuffer_data_len,
    input wire framebuffer_transfer_start,
    // Control signals to fbuf2rgb_line_buffer_writer
    output wire framebuffer_transfer_start_ack,
    output wire framebuffer_transfer_done,
    // Framebuffer line buffer write channel
    output wire [12:0] line_buffer_wraddr,
    output wire [COLOR_WIDTH - 1 : 0] line_buffer_wrdata,
    output wire line_buffer_wrea
);



endmodule
