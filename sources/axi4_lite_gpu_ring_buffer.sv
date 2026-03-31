module axi4_lite_gpu_ring_buffer #(
    parameter ADDRESS_WIDTH = 16,
    parameter DATA_WIDTH = 32,
    parameter BUFFER_SIZE = 32
) (
    // AXI Clock
    input clk,
    input rst_n,
    // Write data channel (input from GPU wrapper)
    input gpu_write_processing_start,
    input [ADDRESS_WIDTH - 1 : 0] gpu_write_address,
    input [DATA_WIDTH - 1 : 0] gpu_write_data,
    output gpu_write_processing_ok,
    output gpu_write_processing_done,
    // Write data channel (output to decoder)
    output decoder_write_processing_start,
    output [ADDRESS_WIDTH - 1 : 0] decoder_write_address,
    output [DATA_WIDTH - 1 : 0] decoder_write_data,
    input decoder_write_processing_ok,
    input decoder_write_processing_done,
    // Status
    output buffer_full,
    output buffer_empty
);

generate
    if (2 ** $clog2(BUFFER_SIZE) != BUFFER_SIZE) begin
        $error("AXI4-LITE GPU buffer size must be a power of 2 (%d)", BUFFER_SIZE);
    end
endgenerate

reg [ADDRESS_WIDTH - 1 : 0] address_buffer [BUFFER_SIZE - 1 : 0];
reg [DATA_WIDTH - 1 : 0] data_buffer [BUFFER_SIZE - 1 : 0];

reg [$clog2(BUFFER_SIZE) - 1 : 0] ring_buffer_read_address;
reg [$clog2(BUFFER_SIZE) - 1 : 0] ring_buffer_write_address;

assign buffer_full = ring_buffer_write_address + $clog2(BUFFER_SIZE)'(1) == ring_buffer_read_address;
assign buffer_empty = ring_buffer_write_address == ring_buffer_read_address;

assign gpu_write_processing_done = gpu_write_processing_start;
assign gpu_write_processing_ok = gpu_write_processing_start && !buffer_full;

assign decoder_write_address = address_buffer[ring_buffer_read_address];
assign decoder_write_data = data_buffer[ring_buffer_read_address];
assign decoder_write_processing_start = !buffer_empty;

always_ff @(posedge clk) begin
    if (!rst_n) begin
        ring_buffer_read_address <= 0;
        ring_buffer_write_address <= 0;
    end else begin
        if (gpu_write_processing_start && !buffer_full) begin
            address_buffer[ring_buffer_write_address] <= gpu_write_address;
            data_buffer[ring_buffer_write_address] <= gpu_write_data;
            ring_buffer_write_address <= ring_buffer_write_address + 1;
        end
        if (decoder_write_processing_done && !buffer_empty) begin
            ring_buffer_read_address <= ring_buffer_read_address + 1;
        end
    end
end

endmodule
