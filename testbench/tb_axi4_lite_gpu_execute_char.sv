module tb_axi4_lite_gpu_execute_char;

localparam FRAME_WIDTH_SCALED = 100;
localparam FRAME_HEIGHT_SCALED = 100;
localparam COLOR_WIDTH = 8;
localparam FBUF_ADDR_WIDTH = 19;
localparam FBUF_DATA_WIDTH = 8;

logic clk = 0;
logic rst_n = 0;

logic start = 0;
logic busy;
logic done;
logic err;

logic xy_valid = 0;
logic [11:0] x = 0;
logic [11:0] y = 0;
logic char_code_valid = 0;
logic [11:0] char_code = 0;
logic color_valid = 0;
logic [COLOR_WIDTH - 1 : 0] color = 0;

logic fbuf_en_wr;
logic fbuf_wrea;
logic [FBUF_ADDR_WIDTH - 1 : 0] fbuf_addr;
logic [FBUF_DATA_WIDTH - 1 : 0] fbuf_data;

axi4_lite_gpu_execute_char #(
    .FRAME_WIDTH_SCALED(FRAME_WIDTH_SCALED),
    .FRAME_HEIGHT_SCALED(FRAME_HEIGHT_SCALED),
    .COLOR_WIDTH(COLOR_WIDTH),
    .FBUF_ADDR_WIDTH(FBUF_ADDR_WIDTH),
    .FBUF_DATA_WIDTH(FBUF_DATA_WIDTH)
) axi4_lite_gpu_execute_char_inst (
    .clk(clk),
    .rst_n(rst_n),

    .start(start),
    .busy(busy),
    .done(done),
    .err(err),

    .xy_valid(xy_valid),
    .x(x),
    .y(y),
    .char_code_valid(char_code_valid),
    .char_code(char_code),
    .color_valid(color_valid),
    .color(color),

    .fbuf_en_wr(fbuf_en_wr),
    .fbuf_wrea(fbuf_wrea),
    .fbuf_addr(fbuf_addr),
    .fbuf_data(fbuf_data)
);

always #5 clk = ~clk;

initial begin
    rst_n = 0;
    #10
    rst_n = 1;
    x = 10;
    y = 10;
    char_code = 1;
    color = 8'b11100000;
    xy_valid = 1;
    char_code_valid = 1;
    color_valid = 1;
    #20
    xy_valid = 0;
    char_code_valid = 0;
    color_valid = 0;
    start = 1;
    #10
    start = 0;
    #1500
    $finish;
end

endmodule
