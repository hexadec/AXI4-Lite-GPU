module tb_fbuf2rgb_line_buffer_writer;

localparam FRAME_H = 40;
localparam FRAME_V = 40;
localparam FRAME_H_TOTAL = 50;
localparam FRAME_V_TOTAL = 50;
localparam SCALING_FACTOR = 2;
localparam COLOR_WIDTH = 8;

logic clk = 0;
logic rst_n = 0;
logic [12:0] h_counter = 0;
logic [12:0] v_counter = 0;
logic [12:0] h_counter_gray;
logic [12:0] v_counter_gray;

logic [31:0] framebuffer_offset_addr;
logic [15:0] framebuffer_data_len;
logic framebuffer_transfer_start;
logic line_buffer_index;

logic framebuffer_transfer_start_ack = 0;
logic framebuffer_transfer_done = 0;

fbuf2rgb_line_buffer_writer #(
    .COLOR_WIDTH(COLOR_WIDTH),
    .FRAME_H(FRAME_H),
    .FRAME_V(FRAME_V),
    .FRAME_H_TOTAL(FRAME_H_TOTAL),
    .FRAME_V_TOTAL(FRAME_V_TOTAL),
    .SCALING_FACTOR(SCALING_FACTOR)
) fbuf2rgb_line_buffer_writer_inst (
    .clk(clk),
    .rst_n(rst_n),
    .h_counter_gray(h_counter_gray),
    .v_counter_gray(v_counter_gray),
    .framebuffer_offset_addr(framebuffer_offset_addr),
    .framebuffer_data_len(framebuffer_data_len),
    .framebuffer_transfer_start(framebuffer_transfer_start),
    .line_buffer_index(line_buffer_index),
    .framebuffer_transfer_start_ack(framebuffer_transfer_start_ack),
    .framebuffer_transfer_done(framebuffer_transfer_done)
);

always #5 clk = ~clk;

always @(posedge clk) begin
    h_counter_gray <= h_counter ^ (h_counter >> 1);
    v_counter_gray <= v_counter ^ (v_counter >> 1);
end

initial begin
    rst_n = 0;
    #20
    rst_n = 1;
    #10
    repeat(45) begin
        #10
        h_counter <= h_counter + 1;
        #10
        v_counter <= v_counter + 1;
    end
    #20
    $finish;
end

endmodule
