module tb_axi4_lite_gpu_execute_cir;

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

logic center_valid = 0;
logic [11:0] center_x = 0;
logic [11:0] center_y = 0;
logic radius_valid = 0;
logic [11:0] radius = 0;
logic color_valid = 0;
logic [COLOR_WIDTH - 1 : 0] color = 0;

logic fbuf_en_wr;
logic fbuf_wrea;
logic [FBUF_ADDR_WIDTH - 1 : 0] fbuf_addr;
logic [FBUF_DATA_WIDTH - 1 : 0] fbuf_data;

axi4_lite_gpu_execute_cir #(
    .FRAME_WIDTH_SCALED(FRAME_WIDTH_SCALED),
    .FRAME_HEIGHT_SCALED(FRAME_HEIGHT_SCALED),
    .COLOR_WIDTH(COLOR_WIDTH),
    .FBUF_ADDR_WIDTH(FBUF_ADDR_WIDTH),
    .FBUF_DATA_WIDTH(FBUF_DATA_WIDTH)
) axi4_lite_gpu_execute_cir_inst (
    .clk(clk),
    .rst_n(rst_n),

    .start(start),
    .busy(busy),
    .done(done),
    .err(err),

    .center_valid(center_valid),
    .center_x(center_x),
    .center_y(center_y),
    .radius(radius),
    .radius_valid(radius_valid),
    .color_valid(color_valid),
    .color(color),

    .fbuf_en_wr(fbuf_en_wr),
    .fbuf_wrea(fbuf_wrea),
    .fbuf_addr(fbuf_addr),
    .fbuf_data(fbuf_data)
);

always #5 clk = ~clk;

int centers_x[4] = '{1, 0, 22, 10};
int centers_y[4] = '{1, 0, 33, 10};
int radii[4] = '{1, 1, 0, 2};
int colors[4] = '{8'hff, 8'hf1, 8'hff, 8'hf1};


int allowed_coordinates_0[5] = {1, 100, 101, 102, 201};
int allowed_coordinates_1[3] = {0, 1, 100};
int allowed_coordinates_2[1] = {3322};
int allowed_coordinates_3[21] = {809, 810, 811, 908, 909, 910, 911, 912, 1008, 1009, 1010, 1011, 1012, 1108, 1109, 1110, 1111, 1112, 1209, 1210, 1211};

int write_count[4] = {5, 3, 1, 21};

task write_circle(input int index);
    int output_counter = 0;
    logic found = 0;
    int index_counter = 0;
    $display("Running test #%d", index);
    rst_n = 1;
    center_x = centers_x[index];
    center_y = centers_y[index];
    center_valid = 1;
    radius = radii[index];
    radius_valid = 1;
    color = colors[index];
    color_valid = 1;
    #20
    center_valid = 0;
    radius_valid = 0;
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
                    2: begin
                        if (fbuf_addr == allowed_coordinates_2[addr_i]) begin
                            found = 1;
                            index_counter += addr_i + 1;
                        end
                    end
                    3: begin
                        if (fbuf_addr == allowed_coordinates_3[addr_i]) begin
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
    write_circle(0);
    #10
    write_circle(1);
    #10
    write_circle(2);
    #10
    write_circle(3);
    #10
    $finish;
end

endmodule
