module tb_axi4_lite_gpu_execute_tri;

localparam FRAME_WIDTH_SCALED = 100;
localparam FRAME_HEIGHT_SCALED = 100;
localparam COLOR_WIDTH = 8;
localparam FBUF_ADDR_WIDTH = 19;
localparam FBUF_DATA_WIDTH = 8;

logic clk = 0;
logic rst_n = 0;

int output_counter = 0;

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
logic xy2_valid = 0;
logic [11:0] x2 = 0;
logic [11:0] y2 = 0;
logic color_valid = 0;
logic [COLOR_WIDTH - 1 : 0] color = 0;

logic fbuf_en_wr;
logic fbuf_wrea;
logic [FBUF_ADDR_WIDTH - 1 : 0] fbuf_addr;
logic [FBUF_DATA_WIDTH - 1 : 0] fbuf_data;

axi4_lite_gpu_execute_tri #(
    .FRAME_WIDTH_SCALED(FRAME_WIDTH_SCALED),
    .FRAME_HEIGHT_SCALED(FRAME_HEIGHT_SCALED),
    .COLOR_WIDTH(COLOR_WIDTH),
    .FBUF_ADDR_WIDTH(FBUF_ADDR_WIDTH),
    .FBUF_DATA_WIDTH(FBUF_DATA_WIDTH)
) axi4_lite_gpu_execute_tri_inst (
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
    .xy2_valid(xy2_valid),
    .x2(x2),
    .y2(y2),
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
    x0 = 1;
    y0 = 5;
    xy0_valid = 1;
    x1 = 5;
    y1 = 1;
    xy1_valid = 1;
    x2 = 5;
    y2 = 5;
    xy2_valid = 1;
    color_valid = 1;
    color = 8'hff;
    #20
    xy0_valid = 0;
    xy1_valid = 0;
    xy2_valid = 0;
    color_valid = 0;
    start = 1;
    #10
    start = 0;
    output_counter = 0;
    while (!done) begin
        #10
        if (fbuf_en_wr && fbuf_wrea) begin
            output_counter = output_counter + 1;
            assert(fbuf_data == color);
            assert( fbuf_addr == 105 || 
                    fbuf_addr == 205 || fbuf_addr == 204 ||
                    fbuf_addr == 305 || fbuf_addr == 304 || fbuf_addr == 303 ||
                    fbuf_addr == 405 || fbuf_addr == 404 || fbuf_addr == 403 || fbuf_addr == 402 ||
                    fbuf_addr == 505 || fbuf_addr == 504 || fbuf_addr == 503 || fbuf_addr == 502 || fbuf_addr == 501);
        end
    end
    #10
    assert(output_counter == 15) else $error("Invalid number of fbuf writes! Expected %d, got %d", 15, output_counter);
    #10
    $finish;
end

endmodule
