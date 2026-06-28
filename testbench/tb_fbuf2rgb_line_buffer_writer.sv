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

logic [12:0] line1_addr;
logic [COLOR_WIDTH - 1 : 0] line1_data;
logic line1_wrea;

logic [12:0] line2_addr;
logic [COLOR_WIDTH - 1 : 0] line2_data;
logic line2_wrea;

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
    .line1_addr(line1_addr),
    .line1_data(line1_data),
    .line1_wrea(line1_wrea),
    .line2_addr(line2_addr),
    .line2_data(line2_data),
    .line2_wrea(line2_wrea)
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
