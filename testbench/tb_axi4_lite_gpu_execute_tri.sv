module tb_axi4_lite_gpu_execute_tri;

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

int coordinates_x0[2] = '{1, 1};
int coordinates_y0[2] = '{5, 1};
int coordinates_x1[2] = '{5, 1};
int coordinates_y1[2] = '{1, 5};
int coordinates_x2[2] = '{5, 5};
int coordinates_y2[2] = '{5, 5};
int colors[2] = '{8'hff, 8'hf1};


int allowed_coordinates_0[15] = {105, 205, 204, 305, 304, 303, 405, 404, 403, 402, 505, 504, 503, 502, 501};
int allowed_coordinates_1[15] = {101, 201, 202, 301, 302, 303, 401, 402, 403, 404, 501, 502, 503, 504, 505};

int write_count[2] = {15, 15};

task write_triangle(input index);
    int output_counter = 0;
    logic found = 0;
    int index_counter = 0;
    $display("Running test #%d", index);
    rst_n = 1;
    x0 = coordinates_x0[index];
    y0 = coordinates_y0[index];
    xy0_valid = 1;
    x1 = coordinates_x1[index];
    y1 = coordinates_y1[index];
    xy1_valid = 1;
    x2 = coordinates_x2[index];
    y2 = coordinates_y2[index];
    xy2_valid = 1;
    color = colors[index];
    color_valid = 1;
    #20
    xy0_valid = 0;
    xy1_valid = 0;
    xy2_valid = 0;
    color_valid = 0;
    start = 1;
    #10
    start = 0;
    output_counter = 0;
    index_counter = 0;
    while (!done) begin
        #10
        if (fbuf_en_wr && fbuf_wrea) begin
            output_counter = output_counter + 1;
            found = 0;
            assert(fbuf_data == colors[index]);
            for (int addr_i = 0; addr_i < write_count[index]; addr_i += 1) begin
                case (index) 
                    0: begin
                        if (fbuf_addr == allowed_coordinates_0[addr_i]) begin
                            found = 1;
                            index_counter += addr_i + 1;
                        end
                    end
                    1: begin
                        if (fbuf_addr == allowed_coordinates_1[addr_i]) begin
                            found = 1;
                            index_counter += addr_i + 1;
                        end
                    end
                endcase
            end
            assert(found) else $error("fbuf_addr (%d) not found in list of allowed values", fbuf_addr);
        end
    end
    #10
    assert(output_counter == write_count[index]) else $error("Invalid number of fbuf writes! Expected %d, got %d", write_count[index], output_counter);
    assert(index_counter == (write_count[index] + 1) * write_count[index] / 2) else $error("Checksum of fbuf_addr mismatch! Expected %d, got %d", index_counter, (write_count[index] + 1) * write_count[index] / 2);
endtask;

initial begin
    rst_n = 0;
    #10
    rst_n = 1;
    #10
    write_triangle(0);
    #10
    write_triangle(1);
    #10
    $finish;
end

endmodule
