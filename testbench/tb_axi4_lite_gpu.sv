module tb_axi4_lite_gpu;

localparam AXI_ADDRESS_WIDTH = 32;
localparam AXI_DATA_WIDTH = 32;
localparam FBUF_ADDR_WIDTH = 19;
localparam FBUF_DATA_WIDTH = 8;
localparam FRAME_WIDTH_SCALED = 640;
localparam FRAME_HEIGHT_SCALED = 480;

logic clk = 0;
logic rst_n = 0;

// Read address channel
logic [AXI_ADDRESS_WIDTH - 1 : 0] s_axi_ctrl_araddr = 0;
logic s_axi_ctrl_arvalid = 0;
logic s_axi_ctrl_arready;
// Read data channel
logic [AXI_DATA_WIDTH - 1 : 0] s_axi_ctrl_rdata;
logic [1:0] s_axi_ctrl_rresp;
logic s_axi_ctrl_rvalid;
logic s_axi_ctrl_rready = 0;
// Write address channel
logic [AXI_ADDRESS_WIDTH - 1 : 0] s_axi_ctrl_awaddr = 0;
logic s_axi_ctrl_awvalid = 0;
logic s_axi_ctrl_awready;
// Write data channel
logic [AXI_DATA_WIDTH - 1 : 0] s_axi_ctrl_wdata = 0;
logic s_axi_ctrl_wvalid = 0;
logic s_axi_ctrl_wready;
// Write response channel
logic [1:0] s_axi_ctrl_bresp;
logic s_axi_ctrl_bvalid;
logic s_axi_ctrl_bready = 0;

// Framebuffer BRAM connection (write only)
logic fbuf_rst_busy;
logic fbuf_en_wr;
logic fbuf_wrea;
logic [FBUF_ADDR_WIDTH - 1 : 0] fbuf_addr;
logic [FBUF_DATA_WIDTH - 1 : 0] fbuf_data;
logic fbuf_rst_req_n;

axi4_lite_gpu #(
    .FRAME_WIDTH_SCALED(FRAME_WIDTH_SCALED),
    .FRAME_HEIGHT_SCALED(FRAME_HEIGHT_SCALED),
    .AXI_ADDRESS_WIDTH(AXI_ADDRESS_WIDTH),
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
    .FBUF_ADDR_WIDTH(FBUF_ADDR_WIDTH),
    .FBUF_DATA_WIDTH(FBUF_DATA_WIDTH)
) axi4_lite_gpu_inst(
    .s_axi_ctrl_aclk(clk),
    .s_axi_ctrl_aresetn(rst_n),
    // Read address channel
    .s_axi_ctrl_araddr(s_axi_ctrl_araddr),
    .s_axi_ctrl_arvalid(s_axi_ctrl_arvalid),
    .s_axi_ctrl_arready(s_axi_ctrl_arready),
    // Read data channel
    .s_axi_ctrl_rdata(s_axi_ctrl_rdata),
    .s_axi_ctrl_rresp(s_axi_ctrl_rresp),
    .s_axi_ctrl_rvalid(s_axi_ctrl_rvalid),
    .s_axi_ctrl_rready(s_axi_ctrl_rready),
    // Write address channel
    .s_axi_ctrl_awaddr(s_axi_ctrl_awaddr),
    .s_axi_ctrl_awvalid(s_axi_ctrl_awvalid),
    .s_axi_ctrl_awready(s_axi_ctrl_awready),
    // Write data channel
    .s_axi_ctrl_wdata(s_axi_ctrl_wdata),
    .s_axi_ctrl_wvalid(s_axi_ctrl_wvalid),
    .s_axi_ctrl_wready(s_axi_ctrl_wready),
    // Write response channel
    .s_axi_ctrl_bresp(s_axi_ctrl_bresp),
    .s_axi_ctrl_bvalid(s_axi_ctrl_bvalid),
    .s_axi_ctrl_bready(s_axi_ctrl_bready),
    // Framebuffer connections
    .fbuf_rst_busy(fbuf_rst_busy),
    .fbuf_en_wr(fbuf_en_wr),
    .fbuf_wrea(fbuf_wrea),
    .fbuf_addr(fbuf_addr),
    .fbuf_data(fbuf_data),
    .fbuf_rst_req_n(fbuf_rst_req_n)
);

task axi4_lite_write(input logic [AXI_ADDRESS_WIDTH - 1 : 0] address, 
                    input logic [AXI_DATA_WIDTH - 1 : 0] data);
    s_axi_ctrl_awaddr = address;
    s_axi_ctrl_awvalid = 1;
    s_axi_ctrl_wdata = data;
    s_axi_ctrl_wvalid = 1;
    #10
    assert(s_axi_ctrl_wready) else $error("WREADY MUST be HIGH after one clock cycle of WVALID");
    assert(s_axi_ctrl_awready) else $error("AWREADY MUST be HIGH after one clock cycle of AWVALID");
    while (!s_axi_ctrl_wready && !s_axi_ctrl_awready) begin
        #10
        $display("Waiting for AWREADY/WREADY (%b, %b)", s_axi_ctrl_awready, s_axi_ctrl_wready);
    end
    s_axi_ctrl_awaddr = 0;
    s_axi_ctrl_awvalid = 0;
    s_axi_ctrl_wdata = 0;
    s_axi_ctrl_wvalid = 0;
    #20 // TODO: decrease to 10
    assert(s_axi_ctrl_bvalid) else $error("BVALID MUST be HIGH");
    while (!s_axi_ctrl_bvalid) begin
        #10
        $display("Waiting for BVALID (%b)", s_axi_ctrl_bvalid);
    end
    assert(s_axi_ctrl_bresp == 2'b00) else $error("BRESP MUST be 2'b00 (RESP_OKAY)");
    s_axi_ctrl_bready = 1;
    #10
    assert(!s_axi_ctrl_bvalid) else $error("BVALID MUST be LOW");
    s_axi_ctrl_bready = 0;
endtask

always #5 clk = ~clk;

assert property (@(posedge clk) !rst_n |-> !s_axi_ctrl_rvalid && !s_axi_ctrl_bvalid)  else $error("All xVALID signals SHOULD be LOW during reset");

assert property (@(posedge clk) !rst_n |-> !s_axi_ctrl_arready && !s_axi_ctrl_awready && !s_axi_ctrl_wready) else $error("All xREADY signals SHOULD be LOW during reset");

int test_read_addresses[4] = '{0, 4, 8, 12};
int test_read_data[4] = '{32'h18, 32'h00, {16'(FRAME_HEIGHT_SCALED), 16'(FRAME_WIDTH_SCALED)}, 32'hffffffff};
logic [1:0] test_read_responses[4] = '{2'b00, 2'b00, 2'b00, 2'b10};

initial begin
    rst_n = 0;
    fbuf_rst_busy = 1;
    #100
    rst_n = 1;
    #10
    for (int i = 0; i < 4; i++) begin
        #10
        $display("Starting read test #%d", i);
        s_axi_ctrl_araddr = test_read_addresses[i];
        s_axi_ctrl_arvalid = 1;
        #10
        assert(s_axi_ctrl_arready) else $error("ARREADY MUST be HIGH after one clock cycle of ARVALID");
        s_axi_ctrl_arvalid = 0;
        s_axi_ctrl_araddr = 32'h00;
        #20 // TODO: Modify according to expected behaviour
        assert(s_axi_ctrl_rvalid) else $error("RVALID MUST be HIGH");
        assert(s_axi_ctrl_rresp == test_read_responses[i]) else $error("RRESP MUST be 2'b%b", test_read_responses[i]);
        assert(s_axi_ctrl_rdata == test_read_data[i]) else $error("RDATA MUST be 32'h%h", test_read_data[i]);
        s_axi_ctrl_rready = 1;
        #10
        assert(!s_axi_ctrl_rvalid) else $error("RVALID MUST be LOW");
        s_axi_ctrl_rready = 0;
    end
    #10
    fbuf_rst_busy = 0;
    $display("Starting single pixel write test...");
    axi4_lite_write(.address(32'h00), .data(32'b00000000011110000000111111100011));
    #10
    $display("Starting rect write test...");
    $display("Writing rect LEFT");
    axi4_lite_write(.address(32'h104), .data(32'({16'd10, 16'd10})));
    #10
    $display("Writing rect RIGHT");
    axi4_lite_write(.address(32'h108), .data(32'({16'd16, 16'd16})));
    #10
    $display("Writing rect COLOR");
    axi4_lite_write(.address(32'h10C), .data(32'b11111100));
    #10
    $display("Writing rect START DRAW");
    axi4_lite_write(.address(32'h100), .data(32'h00));
    #10
    $display("Starting triangle write test...");
    $display("Writing triangle XY0");
    axi4_lite_write(.address(32'h204), .data(32'({16'd10, 16'd1})));
    #10
    $display("Writing triangle XY1");
    axi4_lite_write(.address(32'h208), .data(32'({16'd1, 16'd5})));
    #10
    $display("Writing triangle XY2");
    axi4_lite_write(.address(32'h20C), .data(32'({16'd3, 16'd3})));
    #10
    $display("Writing triangle COLOR");
    axi4_lite_write(.address(32'h210), .data(32'b00011100));
    #10
    $display("Writing triangle START DRAW");
    axi4_lite_write(.address(32'h200), .data(32'h00));
    #10
    $display("Starting circle write test...");
    $display("Writing circle CENTER");
    axi4_lite_write(.address(32'h304), .data(32'({16'd20, 16'd20})));
    #10
    $display("Writing circle RADIUS");
    axi4_lite_write(.address(32'h308), .data(32'd4));
    #10
    $display("Writing circle COLOR");
    axi4_lite_write(.address(32'h30C), .data(32'b00000011));
    #10
    $display("Writing circle START");
    axi4_lite_write(.address(32'h300), .data(32'h00));
    #10
    $display("Starting line write test...");
    $display("Writing line XY0");
    axi4_lite_write(.address(32'h404), .data(32'({16'd20, 16'd40})));
    #10
    $display("Writing line XY1");
    axi4_lite_write(.address(32'h408), .data(32'({16'd40, 16'd10})));
    #10
    $display("Writing line COLOR");
    axi4_lite_write(.address(32'h40C), .data(32'b10000010));
    #10
    $display("Writing line START");
    axi4_lite_write(.address(32'h400), .data(32'h00));
    #4000
    $display("Basic read and write test finished");
    $finish;
end

endmodule
