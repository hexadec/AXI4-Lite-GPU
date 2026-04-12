module bram_to_axi4_lite_dma #(
    parameter FRAME_WIDTH_SCALED = 100,
    parameter FRAME_HEIGHT_SCALED = 100,
    parameter BRAM_ADDRESS_WIDTH = 16,
    parameter BRAM_DATA_WIDTH = 8,
    parameter AXI_ADDRESS_WIDTH = 32,
    parameter AXI_DATA_WIDTH = 32,
    parameter AXI_DMA_BASE_ADDR = 32'h00,
    parameter BUFFER_SIZE = 128
) (
    // AXI global signals
    input m_axi_ctrl_aclk,
    input m_axi_ctrl_aresetn,
    // Read address channel
    output [AXI_ADDRESS_WIDTH - 1 : 0] m_axi_ctrl_araddr,
    output m_axi_ctrl_arvalid,
    input m_axi_ctrl_arready,
    // Read data channel
    input [AXI_DATA_WIDTH - 1 : 0] m_axi_ctrl_rdata,
    input [1:0] m_axi_ctrl_rresp,
    input m_axi_ctrl_rvalid,
    output m_axi_ctrl_rready,
    // Write address channel
    output [AXI_ADDRESS_WIDTH - 1 : 0] m_axi_ctrl_awaddr,
    output m_axi_ctrl_awvalid,
    input m_axi_ctrl_awready,
    // Write data channel
    output [AXI_DATA_WIDTH - 1 : 0] m_axi_ctrl_wdata,
    output m_axi_ctrl_wvalid,
    input m_axi_ctrl_wready,
    // Write response channel
    input [1:0] m_axi_ctrl_bresp,
    input m_axi_ctrl_bvalid,
    output m_axi_ctrl_bready,

    // BRAM controller connection (write only)
    output fbuf_bus_stalled,
    input reg fbuf_en_wr,
    input reg fbuf_wrea,
    input reg [BRAM_ADDRESS_WIDTH - 1 : 0] fbuf_addr,
    input reg [BRAM_DATA_WIDTH - 1 : 0] fbuf_data
);

generate
    if (2 ** $clog2(BUFFER_SIZE) != BUFFER_SIZE) begin
        $error("AXI4-LITE GPU BRAM to AXI4-LITE DMA buffer size must be a power of 2 (%d)", BUFFER_SIZE);
    end
endgenerate

localparam NUMBER_OF_PIXELS = FRAME_WIDTH_SCALED * FRAME_HEIGHT_SCALED;

assign m_axi_ctrl_araddr = 0;
assign m_axi_ctrl_arvalid = 0;
assign m_axi_ctrl_rready = 0;

enum logic [3:0] {
    WR_IDLE,
    WR_WRITE_ADDR_DATA,
    WR_WRITE_ADDR_DATA_INCR,
    WR_ADDR_HANDSHAKE,
    WR_DATA_HANDSHAKE
} state, next_state;

reg [BRAM_ADDRESS_WIDTH - 1 : 0] address_ring_buffer [BUFFER_SIZE - 1 : 0];
reg [BRAM_DATA_WIDTH - 1 : 0] data_ring_buffer [BUFFER_SIZE - 1 : 0];

reg [$clog2(BUFFER_SIZE) - 1 : 0] ring_buffer_read_address;
reg [$clog2(BUFFER_SIZE) - 1 : 0] ring_buffer_write_address;

reg [AXI_ADDRESS_WIDTH - 1 : 0] m_axi_ctrl_awaddr_reg;
reg m_axi_ctrl_awvalid_reg;
reg [AXI_DATA_WIDTH - 1 : 0] m_axi_ctrl_wdata_reg;
reg m_axi_ctrl_wvalid_reg;

assign fbuf_bus_stalled = buffer_full;
assign buffer_full = ring_buffer_write_address + $clog2(BUFFER_SIZE)'(1) == ring_buffer_read_address;
assign buffer_empty = ring_buffer_write_address == ring_buffer_read_address;

assign m_axi_ctrl_awaddr = m_axi_ctrl_awaddr_reg;
assign m_axi_ctrl_awvalid = !m_axi_ctrl_aresetn ? 0 : m_axi_ctrl_awvalid_reg;
assign m_axi_ctrl_wdata = m_axi_ctrl_wdata_reg;
assign m_axi_ctrl_wvalid = !m_axi_ctrl_aresetn ? 0 : m_axi_ctrl_wvalid_reg;

assign m_axi_ctrl_bready = !m_axi_ctrl_aresetn ? 0 : 1;

always_ff @(posedge m_axi_ctrl_aclk) begin
    if (!m_axi_ctrl_aresetn) begin
        ring_buffer_write_address <= 0;
    end else begin
        if (fbuf_en_wr && fbuf_wrea && !buffer_full) begin
            address_ring_buffer[ring_buffer_write_address] <= fbuf_addr;
            data_ring_buffer[ring_buffer_write_address] <= fbuf_data;
            ring_buffer_write_address <= ring_buffer_write_address + 1;
        end
    end
end

always_ff @(posedge m_axi_ctrl_aclk) begin
    if (!m_axi_ctrl_aresetn) begin
        state <= WR_IDLE;
    end else begin
        state <= next_state;
    end
end

always_comb begin
    if (!m_axi_ctrl_aresetn) begin
        next_state = WR_IDLE;
    end else begin
        if (state == WR_IDLE) begin
            if (!buffer_empty) begin
                next_state = WR_WRITE_ADDR_DATA_INCR;
            end else begin
                next_state = WR_IDLE;
            end
        end else if (state == WR_WRITE_ADDR_DATA || state == WR_WRITE_ADDR_DATA_INCR) begin
            if (m_axi_ctrl_awready && m_axi_ctrl_wready) begin
                if (!buffer_empty) begin
                    next_state = WR_WRITE_ADDR_DATA_INCR;
                end else begin
                    next_state = WR_IDLE;
                end
            end else if (m_axi_ctrl_awready) begin
                next_state = WR_ADDR_HANDSHAKE;
            end else if (m_axi_ctrl_wready) begin
                next_state = WR_DATA_HANDSHAKE;
            end else begin
                next_state = WR_WRITE_ADDR_DATA;
            end
        end else if (state == WR_ADDR_HANDSHAKE) begin
            if (m_axi_ctrl_wready) begin
                if (!buffer_empty) begin
                    next_state = WR_WRITE_ADDR_DATA_INCR;
                end else begin
                    next_state = WR_IDLE;
                end
            end else begin
                next_state = WR_ADDR_HANDSHAKE;
            end
        end else if (state == WR_DATA_HANDSHAKE) begin
            if (m_axi_ctrl_awready) begin
                if (!buffer_empty) begin
                    next_state = WR_WRITE_ADDR_DATA_INCR;
                end else begin
                    next_state = WR_IDLE;
                end
            end else begin
                next_state = WR_DATA_HANDSHAKE;
            end
        end else begin
            next_state = WR_IDLE;
        end
    end
end

always_ff @(posedge m_axi_ctrl_aclk) begin
    if (!m_axi_ctrl_aresetn) begin
        m_axi_ctrl_awaddr_reg <= 0;
        m_axi_ctrl_awvalid_reg <= 0;
        m_axi_ctrl_wdata_reg <= 0;
        m_axi_ctrl_wvalid_reg <= 0;
        ring_buffer_read_address <= 32'h00;
    end else begin
        if (state == WR_IDLE) begin
            m_axi_ctrl_awaddr_reg <= 0;
            m_axi_ctrl_awvalid_reg <= 0;
            m_axi_ctrl_wdata_reg <= 0;
            m_axi_ctrl_wvalid_reg <= 0;
        end
        if (state == WR_WRITE_ADDR_DATA || state == WR_WRITE_ADDR_DATA_INCR) begin
            if (state == WR_WRITE_ADDR_DATA_INCR) begin
                ring_buffer_read_address <= ring_buffer_read_address + 1;
                m_axi_ctrl_awaddr_reg <= address_ring_buffer[ring_buffer_read_address] + AXI_DMA_BASE_ADDR;
                m_axi_ctrl_wdata_reg <= data_ring_buffer[ring_buffer_read_address];
            end
            m_axi_ctrl_awvalid_reg <= 1;
            m_axi_ctrl_wvalid_reg <= 1;
        end
        if (state == WR_ADDR_HANDSHAKE) begin
            m_axi_ctrl_awaddr_reg <= 0;
            m_axi_ctrl_awvalid_reg <= 0;
        end
        if (state == WR_DATA_HANDSHAKE) begin
            m_axi_ctrl_wdata_reg <= 0;
            m_axi_ctrl_wvalid_reg <= 0;
        end
    end
end

endmodule
