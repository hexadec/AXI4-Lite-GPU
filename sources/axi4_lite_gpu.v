module axi4_lite_gpu #(
    parameter FRAME_WIDTH_SCALED = 640,
    parameter FRAME_HEIGHT_SCALED = 480,
    parameter AXI_ADDRESS_WIDTH = 32,
    parameter AXI_DATA_WIDTH = 32,
    parameter FBUF_ADDR_WIDTH = 19,
    parameter FBUF_DATA_WIDTH = 8
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

    // Framebuffer BRAM connection (write only)
    input fbuf_rst_busy,
    output reg fbuf_en_wr,
    output reg fbuf_wrea,
    output reg [FBUF_ADDR_WIDTH - 1 : 0] fbuf_addr,
    output reg [FBUF_DATA_WIDTH - 1 : 0] fbuf_data,
    output reg fbuf_rst_req_n
);


wire fbuf_en_wr_int;
wire fbuf_wrea_int;
wire [FBUF_ADDR_WIDTH - 1 : 0] fbuf_addr_int;
wire [FBUF_DATA_WIDTH - 1 : 0] fbuf_data_int;
wire fbuf_rst_req_n_int;

// Store read address from R channel and manage responses
reg read_transaction_ok;
reg [AXI_ADDRESS_WIDTH - 1 : 0] read_address;
reg read_address_ok;
reg s_axi_ctrl_arready_int;

// Connection to AXI GPU command handler
reg [AXI_DATA_WIDTH - 1 : 0] read_data;
reg read_data_ok;
reg [1:0] read_resp;
reg read_processing_start;
wire read_processing_done;
wire [AXI_DATA_WIDTH - 1 : 0] read_data_int;
wire read_resp_ok_int;

// Connection to AXI GPU command handler
reg [1:0] write_response;
reg write_response_ok;
wire write_processing_ok_int;
reg write_processing_start;
wire write_processing_done;

// Store data and address from W/B channels and manage responses
wire write_transaction_ok;
reg [AXI_ADDRESS_WIDTH - 1 : 0] write_address;
reg write_address_ok;
reg s_axi_ctrl_awready_int;

reg [AXI_DATA_WIDTH - 1 : 0] write_data;
reg write_data_ok;
reg s_axi_ctrl_wready_int;

wire decoder_write_processing_start;
wire decoder_write_processing_ok;
wire decoder_write_processing_done;
wire [15:0] decoder_write_address;
wire [AXI_DATA_WIDTH - 1:0] decoder_write_data;

axi4_lite_gpu_ring_buffer #(
    .ADDRESS_WIDTH(16),
    .DATA_WIDTH(AXI_DATA_WIDTH),
    .BUFFER_SIZE(64)
) axi4_lite_gpu_ring_buffer_inst (
    // AXI Clock
    .clk(s_axi_ctrl_aclk),
    .rst_n(s_axi_ctrl_aresetn),
    // Write data channel (input from GPU wrapper)
    .gpu_write_processing_start(write_processing_start),
    .gpu_write_address(write_address[15:0]),
    .gpu_write_data(write_data),
    .gpu_write_processing_ok(write_processing_ok_int),
    .gpu_write_processing_done(write_processing_done),
    // Write data channel (output to decoder)
    .decoder_write_processing_start(decoder_write_processing_start),
    .decoder_write_address(decoder_write_address),
    .decoder_write_data(decoder_write_data),
    .decoder_write_processing_ok(decoder_write_processing_ok),
    .decoder_write_processing_done(decoder_write_processing_done)
);

axi4_lite_gpu_decode #(
    .FRAME_WIDTH_SCALED(FRAME_WIDTH_SCALED),
    .FRAME_HEIGHT_SCALED(FRAME_HEIGHT_SCALED),
    .ADDRESS_WIDTH(16),
    .DATA_WIDTH(AXI_DATA_WIDTH),
    .FBUF_ADDR_WIDTH(FBUF_ADDR_WIDTH),
    .FBUF_DATA_WIDTH(FBUF_DATA_WIDTH)
) axi4_lite_gpu_decode_inst(
    .clk(s_axi_ctrl_aclk),
    .rst_n(s_axi_ctrl_aresetn),
    .read_processing_start(read_processing_start),
    .read_address(read_address[15:0]),
    .read_data(read_data_int),
    .read_resp_ok(read_resp_ok_int),
    .read_processing_done(read_processing_done),
    .write_processing_start(decoder_write_processing_start),
    .write_address(decoder_write_address),
    .write_data(decoder_write_data),
    .write_processing_ok(decoder_write_processing_ok),
    .write_processing_done(decoder_write_processing_done),
    .fbuf_rst_busy(fbuf_rst_busy),
    .fbuf_en_wr(fbuf_en_wr_int),
    .fbuf_wrea(fbuf_wrea_int),
    .fbuf_addr(fbuf_addr_int),
    .fbuf_data(fbuf_data_int),
    .fbuf_rst_req_n(fbuf_rst_req_n_int)
);

always @(posedge s_axi_ctrl_aclk) begin
    fbuf_en_wr <= fbuf_en_wr_int;
    fbuf_wrea <= fbuf_wrea_int;
    fbuf_addr <= fbuf_addr_int;
    fbuf_data <= fbuf_data_int;
    fbuf_rst_req_n <= fbuf_rst_req_n_int;
end

localparam RESP_OKAY = 2'b00;
localparam RESP_SLVERR = 2'b10;

// Store read address and do handshake

assign s_axi_ctrl_arready = !s_axi_ctrl_aresetn ? 0 : s_axi_ctrl_arready_int;

always @(posedge s_axi_ctrl_aclk) begin
    if (!s_axi_ctrl_aresetn) begin
        read_address <= 0;
        read_address_ok <= 0;
        read_processing_start <= 0;
        s_axi_ctrl_arready_int <= 0;
    end else begin
        if (read_transaction_ok) begin
            read_processing_start <= 0;
            read_address <= 0;
            read_address_ok <= 0;
            s_axi_ctrl_arready_int <= 0;
        end else if (s_axi_ctrl_arvalid && (!read_address_ok || read_transaction_ok)) begin
            read_processing_start <= 1;
            read_address <= s_axi_ctrl_araddr;
            read_address_ok <= 1;
            s_axi_ctrl_arready_int <= 1;
        end else begin
            read_processing_start <= 0;
            s_axi_ctrl_arready_int <= 0;
        end
    end
end

// Handle read event
assign s_axi_ctrl_rvalid = !s_axi_ctrl_aresetn ? 0 : (read_transaction_ok ? 0 : read_data_ok);
assign s_axi_ctrl_rdata = !s_axi_ctrl_aresetn ? 0 : (read_transaction_ok ? 0 : read_data);
assign s_axi_ctrl_rresp = !s_axi_ctrl_aresetn ? 0 : (read_transaction_ok ? 0 : read_resp);

always @(posedge s_axi_ctrl_aclk) begin
    if (!s_axi_ctrl_aresetn) begin
        read_data <= 0;
        read_resp <= 0;
        read_data_ok <= 0;
    end else begin
        if (read_transaction_ok) begin
            read_data <= 0;
            read_resp <= 0;
            read_data_ok <= 0;
        end else if (read_processing_done) begin
            read_data <= read_data_int;
            read_resp <= read_resp_ok_int ? RESP_OKAY : RESP_SLVERR;
            read_data_ok <= 1;
        end
    end
end

// Process read requests

// Mark read transaction as OK for one clock cycle when read data channel is ready
always @(posedge s_axi_ctrl_aclk) begin
    if (!s_axi_ctrl_aresetn) begin
        read_transaction_ok <= 0;
    end else begin
        if (read_data_ok && s_axi_ctrl_rready) begin
            read_transaction_ok <= 1;
        end else begin
            read_transaction_ok <= 0;
        end
    end
end


// Store write address and do handshake
assign s_axi_ctrl_awready = !s_axi_ctrl_aresetn ? 0 : s_axi_ctrl_awready_int;

always @(posedge s_axi_ctrl_aclk) begin
    if (!s_axi_ctrl_aresetn) begin
        write_address <= 0;
        write_address_ok <= 0;
        s_axi_ctrl_awready_int <= 0;
    end else begin
        if (write_transaction_ok) begin
            write_address <= 0;
            write_address_ok <= 0;
            s_axi_ctrl_awready_int <= 0;
        end else if (s_axi_ctrl_awvalid && (!write_address_ok || write_transaction_ok)) begin
            write_address <= s_axi_ctrl_awaddr;
            write_address_ok <= 1;
            s_axi_ctrl_awready_int <= 1;
        end else begin
            s_axi_ctrl_awready_int <= 0;
        end
    end
end


// Store write data and do handshake
assign s_axi_ctrl_wready = !s_axi_ctrl_aresetn ? 0 : s_axi_ctrl_wready_int;

always @(posedge s_axi_ctrl_aclk) begin
    if (!s_axi_ctrl_aresetn) begin
        write_data <= 0;
        write_data_ok <= 0;
        s_axi_ctrl_wready_int <= 0;
    end else begin
        if (write_transaction_ok) begin
            write_data <= 0;
            write_data_ok <= 0;
            s_axi_ctrl_wready_int <= 0;
        end if (s_axi_ctrl_wvalid && (!write_data_ok || write_transaction_ok)) begin
            write_data <= s_axi_ctrl_wdata;
            write_data_ok <= 1;
            s_axi_ctrl_wready_int <= 1;
        end else begin
            s_axi_ctrl_wready_int <= 0;
        end
    end
end

// Handle write event when both write address & data channel handshake is done
always @(posedge s_axi_ctrl_aclk) begin
    if (!s_axi_ctrl_aresetn) begin
        write_response <= 2'b00;
        write_response_ok <= 0;
        write_processing_start <= 0;
    end else begin
        if (write_transaction_ok) begin
            write_response <= 2'b00;
            write_response_ok <= 0;
        end else if (write_address_ok && write_data_ok) begin
            if (write_processing_done) begin
                write_response <= write_processing_ok_int ? RESP_OKAY : RESP_SLVERR;
                write_response_ok <= 1;
                write_processing_start <= 0;
            end else if (!write_processing_start && !write_response_ok) begin
                // TODO process data and respond accordingly
                write_processing_start <= 1;
            end else begin
                write_processing_start <= 0;
            end
        end
    end
end

// Mark write transaction as OK for one clock cycle when write response channel is ready
assign write_transaction_ok = !s_axi_ctrl_aresetn ? 0 : write_response_ok && s_axi_ctrl_bready;

assign s_axi_ctrl_bresp = !s_axi_ctrl_aresetn ? 2'b00 : write_response;
assign s_axi_ctrl_bvalid = !s_axi_ctrl_aresetn ? 0 : write_response_ok;

// During reset all xVALID signals must be LOW

endmodule
