module tb_axi4_lite_gpu_execute_line;

localparam FRAME_WIDTH_SCALED = 640;
localparam FRAME_HEIGHT_SCALED = 480;
localparam COLOR_WIDTH = 8;
localparam FBUF_ADDR_WIDTH = 19;
localparam FBUF_DATA_WIDTH = 8;

logic clk = 0;
logic rst_n = 0;

logic start = 0;
logic busy;
logic done;
logic err;

logic xy0_valid = 0;
logic [11:0] x0 = 0;
logic [11:0] y0 = 0;
logic xy1_valid = 0;
logic [11:0] x1 = 0;
logic [11:0] y1 = 0;
logic color_valid = 0;
logic [COLOR_WIDTH - 1 : 0] color = 0;

logic fbuf_en_wr;
logic fbuf_wrea;
logic [FBUF_ADDR_WIDTH - 1 : 0] fbuf_addr;
logic [FBUF_DATA_WIDTH - 1 : 0] fbuf_data;

axi4_lite_gpu_execute_line #(
    .FRAME_WIDTH_SCALED(FRAME_WIDTH_SCALED),
    .FRAME_HEIGHT_SCALED(FRAME_HEIGHT_SCALED),
    .COLOR_WIDTH(COLOR_WIDTH),
    .FBUF_ADDR_WIDTH(FBUF_ADDR_WIDTH),
    .FBUF_DATA_WIDTH(FBUF_DATA_WIDTH)
) axi4_lite_gpu_execute_line_inst (
    .clk(clk),
    .rst_n(rst_n),

    .start(start),
    .busy(busy),
    .done(done),
    .err(err),

    .xy0_valid(xy0_valid),
    .x0(x0),
    .y0(y0),
    .xy1_valid(xy1_valid),
    .x1(x1),
    .y1(y1),
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
    xy0_valid = 1;
    x0 = 20;
    y0 = 10;
    xy1_valid = 1;
    x1 = 10;
    y1 = 20;
    color_valid = 1;
    color = 8'hff;
    #20
    xy0_valid = 0;
    xy1_valid = 0;
    color_valid = 0;
    start = 1;
    #10
    start = 0;
    #1500
    $finish;
end

endmodule
