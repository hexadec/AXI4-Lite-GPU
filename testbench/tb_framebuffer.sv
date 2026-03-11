module tb_framebuffer;

localparam ADDR_WIDTH = 4;
localparam DATA_WIDTH = 8;
localparam FRAME_WIDTH = 4;
localparam FRAME_HEIGHT = 3;
localparam SCALING_FACTOR = 1;

logic clk = 0;
logic rst_req_n = 0;

logic en_wr;
logic en_rd;
logic [ADDR_WIDTH - 1:0] addr_rd;
logic [ADDR_WIDTH - 1:0] addr_wr;
logic [DATA_WIDTH - 1:0] din;
logic [DATA_WIDTH - 1:0] dout;
logic rst_busy;

framebuffer_with_reset #(
    .FRAME_WIDTH(FRAME_WIDTH),
    .FRAME_HEIGHT(FRAME_HEIGHT),
    .SCALING_FACTOR(SCALING_FACTOR),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
) framebuffer_inst (
    .rst_req_n(rst_req_n),
    .clk_wr(clk),
    .clk_rd(clk),
    .en_rd(en_rd),
    .addr_rd(addr_rd),
    .dout(dout),
    .en_wr(en_wr),
    .wrea(en_wr),
    .addr_wr(addr_wr),
    .din(din),
    .rst_busy(rst_busy)
);

always #5 clk = ~clk;

initial begin
    rst_req_n = 0;
    #20
    rst_req_n = 1;
    #1000
    for (int wr_idx = 0; wr_idx < FRAME_WIDTH * FRAME_HEIGHT; wr_idx++) begin
        #10
        en_wr = 1;
        addr_wr = wr_idx;
        din = wr_idx;
    end
    #10
    en_wr = 0;
    addr_wr = 0;
    din = 0;
    for (int rd_idx = 0; rd_idx < FRAME_WIDTH * FRAME_HEIGHT; rd_idx++) begin
        en_rd = 1;
        addr_rd = rd_idx;
        #10
        assert(dout == rd_idx) else $error("Value: %h    Expected: %h", dout, rd_idx);
    end
    en_rd = 0;
    addr_rd = 0;
    rst_req_n = 0;
    #10
    rst_req_n = 1;
    // Start counter from 1: +1 tick has passed
    for (int counter = 1; counter < FRAME_WIDTH * FRAME_HEIGHT; counter++) begin
        #10
        assert(rst_busy == 1) else $error("RST_BUSY should be HIGH");
    end
    #10
    assert(rst_busy == 0) else $error("RST_BUSY should be LOW");
    #10
    en_wr = 0;
    addr_wr = 0;
    din = 0;
    for (int rd_idx = 0; rd_idx < FRAME_WIDTH * FRAME_HEIGHT; rd_idx++) begin
        en_rd = 1;
        addr_rd = rd_idx;
        #10
        assert(dout == 0) else $error("Value: %h    Expected: %h", dout, 0);
    end
    en_rd = 0;
    addr_rd = 0;
    $finish;
end

endmodule
