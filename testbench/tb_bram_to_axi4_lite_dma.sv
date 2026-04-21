module tb_bram_to_axi4_lite_dma;

localparam BRAM_ADDRESS_WIDTH = 19;
localparam BRAM_DATA_WIDTH = 8;
localparam AXI_ADDRESS_WIDTH = 32;
localparam AXI_DATA_WIDTH = 32;
localparam AXI_DMA_BASE_ADDR = 32'h00;
localparam BUFFER_SIZE = 8;

logic clk = 0;
logic rst_n = 0;

logic [AXI_ADDRESS_WIDTH - 1 : 0] m_axi_fbuf_awaddr;
logic m_axi_fbuf_awvalid;
logic m_axi_fbuf_awready = 0;

logic [AXI_DATA_WIDTH - 1 : 0] m_axi_fbuf_wdata;
logic m_axi_fbuf_wvalid;
logic m_axi_fbuf_wready = 0;

logic [1:0] m_axi_fbuf_bresp = 0;
logic m_axi_fbuf_bvalid = 0;
logic m_axi_fbuf_bready;

logic fbuf_bus_stalled;
logic fbuf_en_wr = 0;
logic fbuf_wrea = 0;
logic [BRAM_ADDRESS_WIDTH - 1 : 0] fbuf_addr = 0;
logic [BRAM_DATA_WIDTH - 1 : 0] fbuf_data = 0;

bram_to_axi4_lite_dma #(
    .BRAM_ADDRESS_WIDTH(BRAM_ADDRESS_WIDTH),
    .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
    .AXI_ADDRESS_WIDTH(AXI_ADDRESS_WIDTH),
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
    .AXI_DMA_BASE_ADDR(AXI_DMA_BASE_ADDR),
    .BUFFER_SIZE(BUFFER_SIZE)
) bram_to_axi4_lite_dma_inst (
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
    .m_axi_fbuf_bready(m_axi_fbuf_bready),

    // BRAM controller connection (write only)
    .fbuf_bus_stalled(fbuf_bus_stalled),
    .fbuf_en_wr(fbuf_en_wr),
    .fbuf_wrea(fbuf_wrea),
    .fbuf_addr(fbuf_addr),
    .fbuf_data(fbuf_data)
);

always #5 clk = ~clk;

task axi4_lite_accept_write();
    while (!m_axi_fbuf_awvalid) begin
        #10
        $display("Waiting for AWVALID...");
    end
    $display("AWADDR: %x", m_axi_fbuf_awaddr);
    m_axi_fbuf_awready = 1;
    #10
    m_axi_fbuf_awready = 0;
    while (!m_axi_fbuf_wvalid) begin
        #10
        $display("Waiting for WVALID...");
    end
    $display("WDATA: %x", m_axi_fbuf_wdata);
    m_axi_fbuf_wready = 1;
    #10
    m_axi_fbuf_wready = 0;
    m_axi_fbuf_bresp = 0;
    m_axi_fbuf_bvalid = 1;
    while (!m_axi_fbuf_bready) begin
        #10
        $display("Waiting for BREADY...");
    end
    m_axi_fbuf_bvalid = 0;
    $display("Write transaction completed");
endtask


task fbuf_write(input logic [BRAM_ADDRESS_WIDTH - 1 : 0] address,
                input logic [BRAM_DATA_WIDTH - 1 : 0] data);
    fbuf_en_wr = 1;
    fbuf_wrea = 1;
    fbuf_addr = address;
    fbuf_data = data;
    #10
    fbuf_en_wr = 0;
    fbuf_wrea = 0;
    fbuf_addr = 0;
    fbuf_data = 0;
endtask

initial begin
    #10
    rst_n = 0;
    #10
    rst_n = 1;
    #10
    fbuf_write(32'hf001, 32'hf1);
    axi4_lite_accept_write();
    fbuf_write(32'hf002, 32'hf2);
    fbuf_write(32'hf003, 32'hf3);
    axi4_lite_accept_write();
    axi4_lite_accept_write();
    #100
    $finish();
end

endmodule
