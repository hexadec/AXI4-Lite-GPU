module axi4_lite_gpu_decode #(
    parameter FRAME_WIDTH_SCALED = 640,
    parameter FRAME_HEIGHT_SCALED = 480,
    parameter ADDRESS_WIDTH = 16,
    parameter DATA_WIDTH = 32,
    parameter FBUF_ADDR_WIDTH = 19,
    parameter FBUF_DATA_WIDTH = 8
) (
    // AXI Clock
    input clk,
    input rst_n,
    // Read data channel
    input read_processing_start,
    input [ADDRESS_WIDTH - 1 : 0] read_address,
    output [DATA_WIDTH - 1 : 0] read_data,
    output read_processing_done,
    output read_resp_ok,
    // Write data channel
    input write_processing_start,
    input [ADDRESS_WIDTH - 1 : 0] write_address,
    input [DATA_WIDTH - 1 : 0] write_data,
    output write_processing_ok,
    output write_processing_done,
    // Framebuffer BRAM connection (write only)
    input fbuf_rst_busy,
    output reg fbuf_en_wr,
    output reg fbuf_wrea,
    output reg [FBUF_ADDR_WIDTH - 1 : 0] fbuf_addr,
    output reg [FBUF_DATA_WIDTH - 1 : 0] fbuf_data,
    output reg fbuf_rst_req_n
);

reg read_processing_done_reg;
reg [DATA_WIDTH - 1 : 0] read_data_reg;
reg read_resp_ok_reg;

reg [ADDRESS_WIDTH - 1 : 0] write_addr_reg;
reg [DATA_WIDTH - 1 : 0] write_data_reg;
reg [FBUF_ADDR_WIDTH - 1 : 0] fbuf_single_addr_reg;

assign read_processing_done = !rst_n ? 0 : read_processing_done_reg;
assign read_data = !rst_n ? 0 : read_data_reg;
assign read_resp_ok = !rst_n ? 0 : read_resp_ok_reg;

wire rect_start;
wire rect_busy;
wire rect_done;
wire rect_err;

wire rect_left_valid, rect_right_valid;
wire [11:0] rect_left_x, rect_left_y, rect_right_x, rect_right_y;
wire rect_color_valid;
wire [7:0] rect_color;

wire rect_fbuf_en_wr;
wire rect_fbuf_wrea;
wire [FBUF_ADDR_WIDTH - 1 : 0] rect_fbuf_addr;
wire [FBUF_DATA_WIDTH - 1 : 0] rect_fbuf_data;

axi4_lite_gpu_execute_rect #(
    .FRAME_WIDTH_SCALED(FRAME_WIDTH_SCALED),
    .FRAME_HEIGHT_SCALED(FRAME_HEIGHT_SCALED),
    .COLOR_WIDTH(8),
    .FBUF_ADDR_WIDTH(FBUF_ADDR_WIDTH),
    .FBUF_DATA_WIDTH(FBUF_DATA_WIDTH)
) axi4_lite_gpu_execute_rect_inst (
    .clk(clk),
    .rst_n(rst_n),

    .start(rect_start),
    .busy(rect_busy),
    .done(rect_done),
    .err(rect_err),

    .left_valid(rect_left_valid),
    .left_x(rect_left_x),
    .left_y(rect_left_y),
    .right_valid(rect_right_valid),
    .right_x(rect_right_x),
    .right_y(rect_right_y),
    .color_valid(rect_color_valid),
    .color(rect_color),

    .fbuf_en_wr(rect_fbuf_en_wr),
    .fbuf_wrea(rect_fbuf_wrea),
    .fbuf_addr(rect_fbuf_addr),
    .fbuf_data(rect_fbuf_data)
);

wire tri_start;
wire tri_busy;
wire tri_done;
wire tri_err;

wire tri_xy0_valid, tri_xy1_valid, tri_xy2_valid;
wire [11:0] tri_x0, tri_y0, tri_x1, tri_y1, tri_x2, tri_y2;
wire tri_color_valid;
wire [7:0] tri_color;

wire tri_fbuf_en_wr;
wire tri_fbuf_wrea;
wire [FBUF_ADDR_WIDTH - 1 : 0] tri_fbuf_addr;
wire [FBUF_DATA_WIDTH - 1 : 0] tri_fbuf_data;

axi4_lite_gpu_execute_tri #(
    .FRAME_WIDTH_SCALED(FRAME_WIDTH_SCALED),
    .FRAME_HEIGHT_SCALED(FRAME_HEIGHT_SCALED),
    .COLOR_WIDTH(8),
    .FBUF_ADDR_WIDTH(FBUF_ADDR_WIDTH),
    .FBUF_DATA_WIDTH(FBUF_DATA_WIDTH)
) axi4_lite_gpu_execute_tri_inst (
    .clk(clk),
    .rst_n(rst_n),

    .start(tri_start),
    .busy(tri_busy),
    .done(tri_done),
    .err(tri_err),

    .xy0_valid(tri_xy0_valid),
    .x0(tri_x0),
    .y0(tri_y0),
    .xy1_valid(tri_xy1_valid),
    .x1(tri_x1),
    .y1(tri_y1),
    .xy2_valid(tri_xy2_valid),
    .x2(tri_x2),
    .y2(tri_y2),
    .color_valid(tri_color_valid),
    .color(tri_color),

    .fbuf_en_wr(tri_fbuf_en_wr),
    .fbuf_wrea(tri_fbuf_wrea),
    .fbuf_addr(tri_fbuf_addr),
    .fbuf_data(tri_fbuf_data)
);


wire cir_start;
wire cir_busy;
wire cir_done;
wire cir_err;

wire cir_center_valid, cir_radius_valid;
wire [11:0] cir_center_x, cir_center_y, cir_radius;
wire cir_color_valid;
wire [7:0] cir_color;

wire cir_fbuf_en_wr;
wire cir_fbuf_wrea;
wire [FBUF_ADDR_WIDTH - 1 : 0] cir_fbuf_addr;
wire [FBUF_DATA_WIDTH - 1 : 0] cir_fbuf_data;

axi4_lite_gpu_execute_cir #(
    .FRAME_WIDTH_SCALED(FRAME_WIDTH_SCALED),
    .FRAME_HEIGHT_SCALED(FRAME_HEIGHT_SCALED),
    .COLOR_WIDTH(8),
    .FBUF_ADDR_WIDTH(FBUF_ADDR_WIDTH),
    .FBUF_DATA_WIDTH(FBUF_DATA_WIDTH)
) axi4_lite_gpu_execute_cir_inst (
    .clk(clk),
    .rst_n(rst_n),

    .start(cir_start),
    .busy(cir_busy),
    .done(cir_done),
    .err(cir_err),

    .center_valid(cir_center_valid),
    .center_x(cir_center_x),
    .center_y(cir_center_y),
    .radius_valid(cir_radius_valid),
    .radius(cir_radius),
    .color_valid(cir_color_valid),
    .color(cir_color),

    .fbuf_en_wr(cir_fbuf_en_wr),
    .fbuf_wrea(cir_fbuf_wrea),
    .fbuf_addr(cir_fbuf_addr),
    .fbuf_data(cir_fbuf_data)
);

wire line_start;
wire line_busy;
wire line_done;
wire line_err;

wire line_xy0_valid, line_xy1_valid;
wire [11:0] line_x0, line_y0, line_x1, line_y1;
wire line_color_valid;
wire [7:0] line_color;

wire line_fbuf_en_wr;
wire line_fbuf_wrea;
wire [FBUF_ADDR_WIDTH - 1 : 0] line_fbuf_addr;
wire [FBUF_DATA_WIDTH - 1 : 0] line_fbuf_data;

axi4_lite_gpu_execute_line #(
    .FRAME_WIDTH_SCALED(FRAME_WIDTH_SCALED),
    .FRAME_HEIGHT_SCALED(FRAME_HEIGHT_SCALED),
    .COLOR_WIDTH(8),
    .FBUF_ADDR_WIDTH(FBUF_ADDR_WIDTH),
    .FBUF_DATA_WIDTH(FBUF_DATA_WIDTH)
) axi4_lite_gpu_execute_line_inst (
    .clk(clk),
    .rst_n(rst_n),

    .start(line_start),
    .busy(line_busy),
    .done(line_done),
    .err(line_err),

    .xy0_valid(line_xy0_valid),
    .x0(line_x0),
    .y0(line_y0),
    .xy1_valid(line_xy1_valid),
    .x1(line_x1),
    .y1(line_y1),
    .color_valid(line_color_valid),
    .color(line_color),

    .fbuf_en_wr(line_fbuf_en_wr),
    .fbuf_wrea(line_fbuf_wrea),
    .fbuf_addr(line_fbuf_addr),
    .fbuf_data(line_fbuf_data)
);

wire char_start;
wire char_busy;
wire char_done;
wire char_err;

wire char_xy_valid;
wire [11:0] char_x, char_y;
wire char_code_valid;
wire [11:0] char_code;
wire char_color_valid;
wire [7:0] char_color;

wire char_fbuf_en_wr;
wire char_fbuf_wrea;
wire [FBUF_ADDR_WIDTH - 1 : 0] char_fbuf_addr;
wire [FBUF_DATA_WIDTH - 1 : 0] char_fbuf_data;

axi4_lite_gpu_execute_char #(
    .FRAME_WIDTH_SCALED(FRAME_WIDTH_SCALED),
    .FRAME_HEIGHT_SCALED(FRAME_HEIGHT_SCALED),
    .COLOR_WIDTH(8),
    .FBUF_ADDR_WIDTH(FBUF_ADDR_WIDTH),
    .FBUF_DATA_WIDTH(FBUF_DATA_WIDTH)
) axi4_lite_gpu_execute_char_inst (
    .clk(clk),
    .rst_n(rst_n),

    .start(char_start),
    .busy(char_busy),
    .done(char_done),
    .err(char_err),

    .xy_valid(char_xy_valid),
    .x(char_x),
    .y(char_y),
    .char_code_valid(char_code_valid),
    .char_code(char_code),
    .color_valid(char_color_valid),
    .color(char_color),

    .fbuf_en_wr(char_fbuf_en_wr),
    .fbuf_wrea(char_fbuf_wrea),
    .fbuf_addr(char_fbuf_addr),
    .fbuf_data(char_fbuf_data)
);

enum reg [4:0] {IDLE = 0, BUSY_SINGLE, BUSY_RESET, 
                BUSY_RECT, LOAD_RECT_COORDS_LEFT, LOAD_RECT_COORDS_RIGHT, LOAD_RECT_COLOR,
                BUSY_TRI, LOAD_TRI_COORDS_XY0, LOAD_TRI_COORDS_XY1, LOAD_TRI_COORDS_XY2, LOAD_TRI_COLOR,
                BUSY_CIR, LOAD_CIR_COORDS_CENTER, LOAD_CIR_RADIUS, LOAD_CIR_COLOR,
                BUSY_LINE, LOAD_LINE_COORDS_XY0, LOAD_LINE_COORDS_XY1, LOAD_LINE_COLOR,
                BUSY_CHAR, LOAD_CHAR_XY, LOAD_CHAR_CODE, LOAD_CHAR_COLOR} execute_unit_state, next_state;

assign write_processing_ok = !rst_n ? 0 : (execute_unit_state == IDLE && write_processing_start) ? 1 : 0;
assign write_processing_done = !rst_n ? 0 : (execute_unit_state == IDLE && write_processing_start) ? 1 : 0;

always_ff @(posedge clk) begin
    if (!rst_n) begin
        execute_unit_state <= IDLE;
    end else begin
        execute_unit_state <= next_state;
    end
end

always_comb begin
    if (!rst_n) begin
        next_state = IDLE;
    end else begin
        next_state = IDLE;
        case (execute_unit_state)
            IDLE: begin
                if (write_processing_start) begin
                    case (write_address)
                        32'h00:
                            next_state = BUSY_SINGLE;
                        32'h04:
                            next_state = BUSY_RESET;
                        32'h100:
                            next_state = BUSY_RECT;
                        32'h104:
                            next_state = LOAD_RECT_COORDS_LEFT;
                        32'h108:
                            next_state = LOAD_RECT_COORDS_RIGHT;
                        32'h10C:
                            next_state = LOAD_RECT_COLOR;
                        32'h200:
                            next_state = BUSY_TRI;
                        32'h204:
                            next_state = LOAD_TRI_COORDS_XY0;
                        32'h208:
                            next_state = LOAD_TRI_COORDS_XY1;
                        32'h20C:
                            next_state = LOAD_TRI_COORDS_XY2;
                        32'h210:
                            next_state = LOAD_TRI_COLOR;
                        32'h300:
                            next_state = BUSY_CIR;
                        32'h304:
                            next_state = LOAD_CIR_COORDS_CENTER;
                        32'h308:
                            next_state = LOAD_CIR_RADIUS;
                        32'h30C:
                            next_state = LOAD_CIR_COLOR;
                        32'h400:
                            next_state = BUSY_LINE;
                        32'h404:
                            next_state = LOAD_LINE_COORDS_XY0;
                        32'h408:
                            next_state = LOAD_LINE_COORDS_XY1;
                        32'h40C:
                            next_state = LOAD_LINE_COLOR;
                        32'h500:
                            next_state = BUSY_CHAR;
                        32'h504:
                            next_state = LOAD_CHAR_XY;
                        32'h508:
                            next_state = LOAD_CHAR_CODE;
                        32'h50C:
                            next_state = LOAD_CHAR_COLOR;
                    endcase
                end
            end
            BUSY_RESET:
                if (fbuf_rst_busy) begin
                    next_state = BUSY_RESET;
                end
            BUSY_RECT:
                if ((rect_busy || rect_start) && !rect_done && !rect_err) begin
                    next_state = BUSY_RECT;
                end
            BUSY_TRI:
                if ((tri_busy || tri_start) && !tri_done && !tri_err) begin
                    next_state = BUSY_TRI;
                end
            BUSY_CIR:
                if ((cir_busy || cir_start) && !cir_done && !cir_err) begin
                    next_state = BUSY_CIR;
                end
            BUSY_LINE:
                if ((line_busy || line_start) && !line_done && !line_err) begin
                    next_state = BUSY_LINE;
                end
            BUSY_CHAR:
                if ((char_busy || char_start) && !char_done && !char_err) begin
                    next_state = BUSY_CHAR;
                end
        endcase
    end
end


assign rect_left_valid = (execute_unit_state == LOAD_RECT_COORDS_LEFT);
assign rect_right_valid = (execute_unit_state == LOAD_RECT_COORDS_RIGHT);
assign rect_left_x = write_data_reg[27:16];
assign rect_left_y = write_data_reg[11:0];
assign rect_right_x = write_data_reg[27:16];
assign rect_right_y = write_data_reg[11:0];

assign rect_color_valid = (execute_unit_state == LOAD_RECT_COLOR);
assign rect_color = write_data_reg[7:0];

assign rect_start = (execute_unit_state == BUSY_RECT) && !rect_busy && !rect_done && !rect_err;

assign tri_xy0_valid = (execute_unit_state == LOAD_TRI_COORDS_XY0);
assign tri_xy1_valid = (execute_unit_state == LOAD_TRI_COORDS_XY1);
assign tri_xy2_valid = (execute_unit_state == LOAD_TRI_COORDS_XY2);
assign tri_x0 = write_data_reg[27:16];
assign tri_y0 = write_data_reg[11:0];
assign tri_x1 = write_data_reg[27:16];
assign tri_y1 = write_data_reg[11:0];
assign tri_x2 = write_data_reg[27:16];
assign tri_y2 = write_data_reg[11:0];

assign tri_color_valid = (execute_unit_state == LOAD_TRI_COLOR);
assign tri_color = write_data_reg[7:0];

assign tri_start = (execute_unit_state == BUSY_TRI) && !tri_busy && !tri_done && !tri_err;

assign cir_center_valid = (execute_unit_state == LOAD_CIR_COORDS_CENTER);
assign cir_radius_valid = (execute_unit_state == LOAD_CIR_RADIUS);
assign cir_center_x = write_data_reg[27:16];
assign cir_center_y = write_data_reg[11:0];
assign cir_radius = write_data_reg[11:0];

assign cir_color_valid = (execute_unit_state == LOAD_CIR_COLOR);
assign cir_color = write_data_reg[7:0];

assign cir_start = (execute_unit_state == BUSY_CIR) && !cir_busy && !cir_done && !cir_err;

assign line_xy0_valid = (execute_unit_state == LOAD_LINE_COORDS_XY0);
assign line_xy1_valid = (execute_unit_state == LOAD_LINE_COORDS_XY1);
assign line_x0 = write_data_reg[27:16];
assign line_y0 = write_data_reg[11:0];
assign line_x1 = write_data_reg[27:16];
assign line_y1 = write_data_reg[11:0];

assign line_color_valid = (execute_unit_state == LOAD_LINE_COLOR);
assign line_color = write_data_reg[7:0];

assign line_start = (execute_unit_state == BUSY_LINE) && !line_busy && !line_done && !line_err;

assign char_xy_valid = (execute_unit_state == LOAD_CHAR_XY);
assign char_code_valid = (execute_unit_state == LOAD_CHAR_CODE);
assign char_x = write_data_reg[27:16];
assign char_y = write_data_reg[11:0];
assign char_code = write_data_reg[11:0];

assign char_color_valid = (execute_unit_state == LOAD_CHAR_COLOR);
assign char_color = write_data_reg[7:0];

assign char_start = (execute_unit_state == BUSY_CHAR) && !char_busy && !char_done && !char_err;

always_comb begin
    case (execute_unit_state)
        BUSY_RESET: begin
            fbuf_rst_req_n = write_data_reg == 0; // Only reset if data is non-zero
            fbuf_en_wr = 0;
            fbuf_wrea = 0;
            fbuf_addr = 0;
            fbuf_data = 0;
        end
        BUSY_SINGLE: begin
            fbuf_rst_req_n = 1;
            fbuf_en_wr = 1;
            fbuf_wrea = 1;
            fbuf_data = write_data_reg[7:0];
            fbuf_addr = fbuf_single_addr_reg;
        end
        BUSY_RECT: begin
            fbuf_rst_req_n = 1;
            fbuf_en_wr = rect_fbuf_en_wr;
            fbuf_wrea = rect_fbuf_wrea;
            fbuf_addr = rect_fbuf_addr;
            fbuf_data = rect_fbuf_data;
        end
        BUSY_TRI: begin
            fbuf_rst_req_n = 1;
            fbuf_en_wr = tri_fbuf_en_wr;
            fbuf_wrea = tri_fbuf_wrea;
            fbuf_addr = tri_fbuf_addr;
            fbuf_data = tri_fbuf_data;
        end
        BUSY_CIR: begin
            fbuf_rst_req_n = 1;
            fbuf_en_wr = cir_fbuf_en_wr;
            fbuf_wrea = cir_fbuf_wrea;
            fbuf_addr = cir_fbuf_addr;
            fbuf_data = cir_fbuf_data;
        end
        BUSY_LINE: begin
            fbuf_rst_req_n = 1;
            fbuf_en_wr = line_fbuf_en_wr;
            fbuf_wrea = line_fbuf_wrea;
            fbuf_addr = line_fbuf_addr;
            fbuf_data = line_fbuf_data;
        end
        BUSY_CHAR: begin
            fbuf_rst_req_n = 1;
            fbuf_en_wr = char_fbuf_en_wr;
            fbuf_wrea = char_fbuf_wrea;
            fbuf_addr = char_fbuf_addr;
            fbuf_data = char_fbuf_data;
        end
        default: begin
            fbuf_rst_req_n = 1;
            fbuf_en_wr = 0;
            fbuf_wrea = 0;
            fbuf_addr = 0;
            fbuf_data = 0;
        end
    endcase
end


always_ff @(posedge clk) begin
    if (!rst_n) begin
        read_processing_done_reg <= 0;
        read_data_reg <= 0;
        read_resp_ok_reg <= 0;
    end else begin
        if (read_processing_start) begin
            if (read_address == 32'h0) begin // Use 0x00 as status register
                read_data_reg <= {27'h0, fbuf_rst_busy, read_processing_start, read_processing_done_reg, write_processing_start, write_processing_done};
                read_processing_done_reg <= 1;
                read_resp_ok_reg <= 1;
            end else if (read_address == 32'h4) begin // Use 0x04 as state register
                read_data_reg <= execute_unit_state;
                read_processing_done_reg <= 1;
                read_resp_ok_reg <= 1;
            end else if (read_address == 32'h8) begin // Use 0x08 as resolution query register
                read_data_reg[15:0] <= FRAME_WIDTH_SCALED;
                read_data_reg[31:16] <= FRAME_HEIGHT_SCALED;
                read_processing_done_reg <= 1;
                read_resp_ok_reg <= 1;
            end else begin
                // TODO
                read_data_reg <= 32'hffffffff;
                read_processing_done_reg <= 1;
                read_resp_ok_reg <= 0;
            end
        end else begin
            read_processing_done_reg <= 0;
            read_data_reg <= 0;
            read_resp_ok_reg <= 0;
        end
    end
end

always_ff @(posedge clk) begin
    if (!rst_n) begin
        write_addr_reg <= 0;
        write_data_reg <= 0;
        fbuf_single_addr_reg <= 0;
    end else begin
        if (write_processing_start && execute_unit_state == IDLE) begin
            write_addr_reg <= write_address;
            write_data_reg <= write_data;
            fbuf_single_addr_reg <= write_data[31:20] + write_data[19:8] * FRAME_WIDTH_SCALED;
        end
    end
end

endmodule
