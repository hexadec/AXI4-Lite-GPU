module tb_axi4_lite_gpu;

localparam AXI_ADDRESS_WIDTH = 32;
localparam AXI_DATA_WIDTH = 32;
localparam FBUF_ADDR_WIDTH = 19;
localparam FBUF_DATA_WIDTH = 8;
localparam FRAME_WIDTH_SCALED = 100;
localparam FRAME_HEIGHT_SCALED = 100;

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


// Framebuffer AXI connection
logic [AXI_ADDRESS_WIDTH - 1 : 0] m_axi_fbuf_awaddr;
logic m_axi_fbuf_awvalid;
logic m_axi_fbuf_awready = 0;

logic [AXI_DATA_WIDTH - 1 : 0] m_axi_fbuf_wdata;
logic m_axi_fbuf_wvalid;
logic m_axi_fbuf_wready = 0;

logic [1:0] m_axi_fbuf_bresp = 0;
logic m_axi_fbuf_bvalid = 0;
logic m_axi_fbuf_bready;

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
    
    // AXI global signals
    .m_axi_fbuf_aclk(clk),
    .m_axi_fbuf_aresetn(rst_n),
    // Write address channel
    .m_axi_fbuf_awaddr(m_axi_fbuf_awaddr),
    .m_axi_fbuf_awvalid(m_axi_fbuf_awvalid),
    .m_axi_fbuf_awready(m_axi_fbuf_awready),
    // Write data channel
    .m_axi_fbuf_wdata(m_axi_fbuf_wdata),
    .m_axi_fbuf_wvalid(m_axi_fbuf_wvalid),
    .m_axi_fbuf_wready(m_axi_fbuf_wready),
    // Write response channel
    .m_axi_fbuf_bresp(m_axi_fbuf_bresp),
    .m_axi_fbuf_bvalid(m_axi_fbuf_bvalid),
    .m_axi_fbuf_bready(m_axi_fbuf_bready)
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

task axi4_lite_accept_write();
    while (!m_axi_fbuf_awvalid) begin
        #10
        m_axi_fbuf_awready = 0;
    end
    $display("AWADDR: %x", m_axi_fbuf_awaddr);
    m_axi_fbuf_awready = 1;
    #10
    m_axi_fbuf_awready = 0;
    while (!m_axi_fbuf_wvalid) begin
        #10
        m_axi_fbuf_awready = 0;
    end
    $display("WDATA: %x", m_axi_fbuf_wdata);
    m_axi_fbuf_wready = 1;
    #10
    m_axi_fbuf_wready = 0;
    m_axi_fbuf_bresp = 0;
    m_axi_fbuf_bvalid = 1;
    while (!m_axi_fbuf_bready) begin
        #10
        m_axi_fbuf_bvalid = 1;
    end
    m_axi_fbuf_bvalid = 0;
    $display("Write transaction completed");
endtask

always #5 clk = ~clk;

// All xVALID signals MUST be LOW during reset
assert property (@(posedge clk) !rst_n |-> !s_axi_ctrl_rvalid && !s_axi_ctrl_bvalid)  else $error("All xVALID signals MUST be LOW during reset");

// ALL xREADY signals MUST be LOW during reset
assert property (@(posedge clk) !rst_n |-> !s_axi_ctrl_arready && !s_axi_ctrl_awready && !s_axi_ctrl_wready) else $error("All xREADY signals MUST be LOW during reset");

//ARREADY MUST be HIGH after one clock cycle of ARVALID
assert property (@(posedge clk) s_axi_ctrl_arvalid |-> ##1 s_axi_ctrl_arready) else $error("ARREADY MUST be HIGH after one clock cycle of ARVALID");

//AWREADY MUST be HIGH after one clock cycle of AWVALID
assert property (@(posedge clk) s_axi_ctrl_awvalid |-> ##1 s_axi_ctrl_awready) else $error("AWREADY MUST be HIGH after one clock cycle of AWVALID");

//WREADY MUST be HIGH after one clock cycle of WVALID
assert property (@(posedge clk) s_axi_ctrl_wvalid |-> ##1 s_axi_ctrl_wready) else $error("WREADY MUST be HIGH after one clock cycle of WVALID");

//BVALID MUST be HIGH after one-three clock cycles of WVALID and AWVALID
assert property (@(posedge clk) ((s_axi_ctrl_wvalid ##[0:4] s_axi_ctrl_awvalid || s_axi_ctrl_awvalid ##[0:4] s_axi_ctrl_wvalid)) |-> ##[1:3] s_axi_ctrl_bvalid) else $error("BVALID MUST be HIGH after one-three clock cycles of WVALID and AWVALID");

int test_read_addresses[4] = '{0, 4, 8, 12};
int test_read_data[4] = '{32'h58, 32'h00, {16'(FRAME_HEIGHT_SCALED), 16'(FRAME_WIDTH_SCALED)}, 32'hffffffff};
logic [1:0] test_read_responses[4] = '{2'b00, 2'b00, 2'b00, 2'b10};

initial begin
    rst_n = 0;
    #100
    fork
        #10 $display("Forking AXI4-LITE accept write task");
        begin
            for (int i = 0; i < 1000; i++) begin
                axi4_lite_accept_write();
            end
        end
    join_any
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
    #10
    $display("Starting char write test...");
    $display("Writing char XY");
    axi4_lite_write(.address(32'h504), .data(32'({16'd0, 16'd0})));
    #10
    $display("Writing char code");
    axi4_lite_write(.address(32'h508), .data(32'd4));
    #10
    $display("Writing char COLOR");
    axi4_lite_write(.address(32'h50C), .data(32'b11000011));
    #10
    $display("Writing char START");
    axi4_lite_write(.address(32'h500), .data(32'h00));
    #4000
    $display("Basic read and write test finished");
    $finish;
end

endmodule
