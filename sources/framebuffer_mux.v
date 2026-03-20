module framebuffer_mux #(
    parameter FBUF_ADDR_WIDTH = 19,
    parameter FBUF_DATA_WIDTH = 8
) (
    input sel,
    // Framebuffer input CH0
    input ch0_fbuf_en_wr,
    input ch0_fbuf_wrea,
    input [FBUF_ADDR_WIDTH - 1 : 0] ch0_fbuf_addr,
    input [FBUF_DATA_WIDTH - 1 : 0] ch0_fbuf_data,
    input ch0_fbuf_rst_req_n,
    // Framebuffer input CH1
    input ch1_fbuf_en_wr,
    input ch1_fbuf_wrea,
    input [FBUF_ADDR_WIDTH - 1 : 0] ch1_fbuf_addr,
    input [FBUF_DATA_WIDTH - 1 : 0] ch1_fbuf_data,
    input ch1_fbuf_rst_req_n,
    // Framebuffer BRAM connection (write only)
    output fbuf_en_wr,
    output fbuf_wrea,
    output [FBUF_ADDR_WIDTH - 1 : 0] fbuf_addr,
    output [FBUF_DATA_WIDTH - 1 : 0] fbuf_data,
    output fbuf_rst_req_n
);

assign fbuf_en_wr = !sel ? ch0_fbuf_en_wr : ch1_fbuf_en_wr;
assign fbuf_wrea = !sel ? ch0_fbuf_wrea : ch1_fbuf_wrea;
assign fbuf_addr = !sel ? ch0_fbuf_addr : ch1_fbuf_addr;
assign fbuf_data = !sel ? ch0_fbuf_data : ch1_fbuf_data;
assign fbuf_rst_req_n = !sel ? ch0_fbuf_rst_req_n : ch1_fbuf_rst_req_n;

endmodule
