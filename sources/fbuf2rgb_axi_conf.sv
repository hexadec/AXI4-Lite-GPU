module fbuf2rgb_axi_conf #(
    parameter AXI_ADDRESS_WIDTH = 32,
    parameter AXI_DATA_WIDTH = 32
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

    // registers
    output reg [AXI_DATA_WIDTH - 1 : 0] framebuffer_dma_offset
);

localparam RESP_OKAY = 2'b00;
localparam RESP_SLVERR = 2'b10;

assign s_axi_ctrl_arready = 0;
assign s_axi_ctrl_rdata = 0;
assign s_axi_ctrl_rresp = 0;
assign s_axi_ctrl_rvalid = 0;

enum logic [3:0] {
    WR_IDLE,
    WR_WRITE_ADDR_DATA,
    WR_ADDR_HANDSHAKE,
    WR_DATA_HANDSHAKE,
    WR_BRESP
} state, next_state;

reg [AXI_ADDRESS_WIDTH - 1 : 0] s_axi_ctrl_awaddr_reg;
reg [AXI_DATA_WIDTH - 1 : 0] s_axi_ctrl_wdata_reg;
reg s_axi_ctrl_awready_reg;
reg s_axi_ctrl_wready_reg;
reg [1:0] s_axi_ctrl_bresp_reg;
reg s_axi_ctrl_bvalid_reg;

assign s_axi_ctrl_awready = !s_axi_ctrl_aresetn ? 0 : s_axi_ctrl_awready_reg;
assign s_axi_ctrl_wready = !s_axi_ctrl_aresetn ? 0 : s_axi_ctrl_wready_reg;
assign s_axi_ctrl_bresp = !s_axi_ctrl_bresp_reg ? 0 : s_axi_ctrl_bresp_reg;
assign s_axi_ctrl_bvalid = !s_axi_ctrl_bvalid_reg ? 0 : s_axi_ctrl_bvalid_reg;

always_comb begin
    if (!s_axi_ctrl_aresetn) begin
        next_state = WR_IDLE;
    end else begin
        if (state == WR_IDLE) begin
            if (s_axi_ctrl_awvalid && s_axi_ctrl_wvalid) begin
                next_state = WR_WRITE_ADDR_DATA;
            end else if (s_axi_ctrl_awvalid) begin
                next_state = WR_ADDR_HANDSHAKE;
            end else if (s_axi_ctrl_wvalid) begin
                next_state = WR_DATA_HANDSHAKE;
            end else begin
                next_state = WR_IDLE;
            end
        end else if (state == WR_WRITE_ADDR_DATA) begin
            next_state = WR_BRESP;
        end else if (state == WR_BRESP) begin
            if (s_axi_ctrl_bready) begin
                next_state = WR_IDLE;
            end else begin
                next_state = WR_BRESP;
            end
        end else if (state == WR_ADDR_HANDSHAKE) begin
            if (s_axi_ctrl_wvalid) begin
                next_state = WR_WRITE_ADDR_DATA;
            end else begin
                next_state = WR_ADDR_HANDSHAKE;
            end
        end else if (state == WR_DATA_HANDSHAKE) begin
            if (s_axi_ctrl_awvalid) begin
                next_state = WR_WRITE_ADDR_DATA;
            end else begin
                next_state = WR_DATA_HANDSHAKE;
            end
        end else begin
            next_state = WR_IDLE;
        end
    end
end

always_ff @(posedge s_axi_ctrl_aclk) begin
    if (!s_axi_ctrl_aresetn) begin
        framebuffer_dma_offset <= 0;
        s_axi_ctrl_awaddr_reg <= 0;
        s_axi_ctrl_wdata_reg <= 0;
        s_axi_ctrl_awready_reg <= 0;
        s_axi_ctrl_wready_reg <= 0;
        s_axi_ctrl_bresp_reg <= 0;
        s_axi_ctrl_bvalid_reg <= 0;
    end else begin
        if (state == WR_IDLE) begin
            if (s_axi_ctrl_awvalid) begin
                s_axi_ctrl_awaddr_reg <= s_axi_ctrl_awaddr;
                s_axi_ctrl_awready_reg <= 1;
            end
            if (s_axi_ctrl_wvalid) begin
                s_axi_ctrl_wdata_reg <= s_axi_ctrl_wdata;
                s_axi_ctrl_wready_reg <= 1;
            end
        end else if (state == WR_WRITE_ADDR_DATA) begin
            s_axi_ctrl_awready_reg <= 0;
            s_axi_ctrl_wready_reg <= 0;
            s_axi_ctrl_bvalid_reg <= 1;
            if (s_axi_ctrl_awaddr_reg[7:0] == 8'h00) begin
                framebuffer_dma_offset <= s_axi_ctrl_wdata_reg;
                s_axi_ctrl_bresp_reg <= RESP_OKAY;
            end else begin
                s_axi_ctrl_bresp_reg <= RESP_SLVERR;
            end
        end else if (state == WR_ADDR_HANDSHAKE) begin
            s_axi_ctrl_awready_reg <= 0;
            if (s_axi_ctrl_wvalid) begin
                s_axi_ctrl_wdata_reg <= s_axi_ctrl_wdata;
                s_axi_ctrl_wready_reg <= 1;
            end
        end else if (state == WR_DATA_HANDSHAKE) begin
            s_axi_ctrl_wready_reg <= 0;
            if (s_axi_ctrl_awvalid) begin
                s_axi_ctrl_awaddr_reg <= s_axi_ctrl_awaddr;
                s_axi_ctrl_awready_reg <= 1;
            end
        end else if (state == WR_BRESP) begin
            s_axi_ctrl_bresp_reg <= 0;
            s_axi_ctrl_bvalid_reg <= 0;
        end
    end
end

endmodule
