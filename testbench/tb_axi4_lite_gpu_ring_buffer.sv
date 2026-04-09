module tb_axi4_lite_gpu_ring_buffer;

localparam ADDRESS_WIDTH = 16;
localparam DATA_WIDTH = 32;
localparam BUFFER_SIZE = 8;

logic clk = 0;
logic rst_n = 0;

logic gpu_write_processing_start = 0;
logic [ADDRESS_WIDTH - 1 : 0] gpu_write_address = 0;
logic [DATA_WIDTH - 1 : 0] gpu_write_data = 0;
logic gpu_write_processing_ok;
logic gpu_write_processing_done;

logic decoder_write_processing_start;
logic [ADDRESS_WIDTH - 1 : 0] decoder_write_address;
logic [DATA_WIDTH - 1 : 0] decoder_write_data;
logic decoder_write_processing_ok = 0;
logic decoder_write_processing_done = 0;

logic buffer_full;
logic buffer_empty;

axi4_lite_gpu_ring_buffer #(
    .ADDRESS_WIDTH(ADDRESS_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .BUFFER_SIZE(BUFFER_SIZE)
) axi4_lite_gpu_ring_buffer_inst (
    // AXI Clock
    .clk(clk),
    .rst_n(rst_n),
    // Write data channel (input from GPU wrapper)
    .gpu_write_processing_start(gpu_write_processing_start),
    .gpu_write_address(gpu_write_address),
    .gpu_write_data(gpu_write_data),
    .gpu_write_processing_ok(gpu_write_processing_ok),
    .gpu_write_processing_done(gpu_write_processing_done),
    // Write data channel (output to decoder)
    .decoder_write_processing_start(decoder_write_processing_start),
    .decoder_write_address(decoder_write_address),
    .decoder_write_data(decoder_write_data),
    .decoder_write_processing_ok(decoder_write_processing_ok),
    .decoder_write_processing_done(decoder_write_processing_done),
    // Status
    .buffer_full(buffer_full),
    .buffer_empty(buffer_empty)
);

always #5 clk = ~clk;

initial begin
    rst_n = 0;
    #100
    rst_n = 1;
    #10
    assert(buffer_empty);
    for (int i = 0; i < BUFFER_SIZE + 1; i++) begin
        #10
        gpu_write_processing_start = 1;
        gpu_write_address = i << 4;
        gpu_write_data = i;
        #10
        gpu_write_processing_start = 0;
        gpu_write_address = 0;
        gpu_write_data = 0;
        assert(!buffer_empty);
        if (i >= BUFFER_SIZE - 1) begin
            assert(buffer_full);
        end
    end
    assert(buffer_full);
    for (int i = 0; i < BUFFER_SIZE + 1; i++) begin
        #10
        if (i < BUFFER_SIZE - 1) begin
            assert(decoder_write_address == i << 4);
            assert(decoder_write_data == i);
        end
        decoder_write_processing_ok = 1;
        decoder_write_processing_done = 1;
        #10
        decoder_write_processing_ok = 0;
        decoder_write_processing_done = 0;
        assert(!buffer_full);
        if (i >= BUFFER_SIZE - 1) begin
            assert(buffer_empty);
        end
    end
    #100
    $finish;
end

endmodule
