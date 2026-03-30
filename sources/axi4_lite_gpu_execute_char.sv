module axi4_lite_gpu_execute_char #(
    parameter FRAME_WIDTH_SCALED = 640,
    parameter FRAME_HEIGHT_SCALED = 480,
    parameter COLOR_WIDTH = 8,
    parameter FBUF_ADDR_WIDTH = 19,
    parameter FBUF_DATA_WIDTH = 8
) (
    input clk,
    input rst_n,
    input start,
    output busy,
    output done,
    output err,

    input xy_valid,
    input [11:0] x,
    input [11:0] y,
    input char_code_valid,
    input [11:0] char_code,
    input color_valid,
    input [COLOR_WIDTH - 1 : 0] color,

    output fbuf_en_wr,
    output fbuf_wrea,
    output [FBUF_ADDR_WIDTH - 1 : 0] fbuf_addr,
    output [FBUF_DATA_WIDTH - 1 : 0] fbuf_data
);

localparam CHAR_WIDTH = 8;
localparam CHAR_HEIGHT = 8;
localparam CHARACTER_COUNT = 65;

enum logic [2:0] {  IDLE = 0,
                    BUSY_GETROW, 
                    BUSY_WRITE,
                    BUSY_LASTWRITE,
                    DONE, 
                    ERR} state, next_state;

reg xy_valid_int;
reg char_code_valid_int;
reg color_valid_int;

reg [11:0] x_int;
reg [11:0] y_int;
reg [11:0] char_code_int;
reg [COLOR_WIDTH - 1 : 0] color_int;

reg [11:0] fbuf_pos_x, fbuf_pos_y, char_pos_x, char_pos_y;
reg [11:0] fbuf_max_x, fbuf_max_y, char_max_x, char_max_y;
reg [11:0] fbuf_min_x, fbuf_min_y, char_min_x, char_min_y;

reg [CHAR_WIDTH - 1 : 0] character_row;

reg [FBUF_ADDR_WIDTH - 1 : 0] fbuf_addr_int;

wire char_rom_en;
assign char_rom_en = state == BUSY_GETROW;

axi4_lite_gpu_char_rom #(
    .CHAR_WIDTH(CHAR_WIDTH),
    .CHAR_HEIGHT(CHAR_HEIGHT),
    .CHARACTER_COUNT(CHARACTER_COUNT)
) axi4_lite_gpu_char_rom_inst (
    .clk(clk),
    .en(char_rom_en),
    .char_code(char_code_int),
    .char_row_addr(char_pos_y),
    .char_row(character_row)
);


assign busy = state == BUSY_GETROW || state == BUSY_WRITE || state == BUSY_LASTWRITE;
assign done = state == DONE;
assign err = state == ERR;


always_ff @(posedge clk) begin
    if (!rst_n) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end


always_comb begin
    if (!rst_n) begin
        next_state = IDLE;
    end else if (state == IDLE) begin
        if ((xy_valid && (x >= FRAME_WIDTH_SCALED || y >= FRAME_HEIGHT_SCALED)) ||
            (char_code_valid && char_code >= CHARACTER_COUNT)) begin
            next_state = ERR;
        end else if (start && xy_valid_int && char_code_valid_int && color_valid_int) begin
            next_state = BUSY_GETROW;
        end else if (start) begin
            next_state = ERR;
        end else begin
            next_state = IDLE;
        end
    end else if (state == BUSY_GETROW) begin
        next_state = BUSY_WRITE;
    end else if (state == BUSY_WRITE) begin
        if (fbuf_pos_x == fbuf_max_x && fbuf_pos_y == fbuf_max_y) begin
            next_state = BUSY_LASTWRITE;
        end else if (char_pos_x == char_min_x) begin
            next_state = BUSY_GETROW;
        end else begin
            next_state = BUSY_WRITE;
        end
    end else if (state == BUSY_LASTWRITE) begin
        next_state = DONE;
    end else if (state == DONE) begin
        next_state = IDLE;
    end else if (state == ERR) begin
        next_state = IDLE;
    end else begin
        next_state = ERR;
    end
end


always_ff @(posedge clk) begin
    if (!rst_n) begin
        xy_valid_int <= 0;
        char_code_valid_int <= 0;
        color_valid_int <= 0;
        x_int <= 0;
        y_int <= 0;
        char_code_int <= 0;
        color_int <= 0;
    end else begin
        if (state == IDLE) begin
            if (xy_valid) begin
                xy_valid_int <= 1;
                x_int <= x;
                y_int <= y;
            end
            if (char_code_valid) begin
                char_code_valid_int <= 1;
                char_code_int <= char_code;
            end
            if (color_valid) begin
                color_valid_int <= 1;
                color_int <= color;
            end
        end else if (state == DONE || state == ERR) begin
            xy_valid_int <= 0;
            char_code_valid_int <= 0;
            color_valid_int <= 0;
            x_int <= 0;
            y_int <= 0;
            char_code_int <= 0;
            color_int <= 0;
        end
    end
end


always_ff @(posedge clk) begin
    if (!rst_n) begin
        fbuf_min_x <= 0;
        fbuf_min_y <= 0;
        fbuf_max_x <= 0;
        fbuf_max_y <= 0;
        fbuf_pos_x <= 0;
        fbuf_pos_y <= 0;
        char_min_x <= 0;
        char_min_y <= 0;
        char_max_x <= 0;
        char_max_y <= 0;
        char_pos_x <= 0;
        char_pos_y <= 0;
        fbuf_addr_int <= 0;
    end else begin
        if (state == IDLE) begin
            if (start && xy_valid_int && char_code_valid_int && color_valid_int) begin
                fbuf_min_x <= x_int;
                fbuf_min_y <= y_int;
                fbuf_max_x <= FRAME_WIDTH_SCALED > x_int + CHAR_WIDTH ? x_int + CHAR_WIDTH - 1 : FRAME_WIDTH_SCALED - 1;
                fbuf_max_y <= FRAME_HEIGHT_SCALED > y_int + CHAR_HEIGHT ? y_int + CHAR_HEIGHT - 1 : FRAME_HEIGHT_SCALED - 1;
                char_min_x <= 0;
                char_min_y <= 0;
                char_max_x <= CHAR_WIDTH - 1;
                char_max_y <= CHAR_HEIGHT - 1;

                fbuf_pos_x <= x_int; // == fbuf_min_x
                fbuf_pos_y <= y_int; // == fbuf_min_y
                char_pos_x <= CHAR_WIDTH - 1;
                char_pos_y <= 0;
            end
        end else if (state == BUSY_GETROW) begin
            if (char_pos_y == 0) begin
                if (fbuf_pos_x < fbuf_max_x) begin
                    fbuf_pos_x <= fbuf_pos_x + 1;
                end else begin
                    fbuf_pos_x <= fbuf_min_x;
                    if (fbuf_pos_y < fbuf_max_y) begin
                        fbuf_pos_y <= fbuf_pos_y + 1;
                    end
                end
                fbuf_addr_int <= (fbuf_pos_y) * FBUF_ADDR_WIDTH'(FRAME_WIDTH_SCALED) + fbuf_pos_x;
            end
        end else if (state == BUSY_WRITE) begin
            if (fbuf_pos_x < fbuf_max_x) begin
                fbuf_pos_x <= fbuf_pos_x + 1;
            end else begin
                fbuf_pos_x <= fbuf_min_x;
                if (fbuf_pos_y < fbuf_max_y) begin
                    fbuf_pos_y <= fbuf_pos_y + 1;
                end
            end
            if (char_pos_x > char_min_x) begin
                char_pos_x <= char_pos_x - 1;
            end else begin
                char_pos_x <= char_max_x;
                if (char_pos_y < char_max_y) begin
                    char_pos_y <= char_pos_y + 1;
                end
            end
            fbuf_addr_int <= (fbuf_pos_y) * FBUF_ADDR_WIDTH'(FRAME_WIDTH_SCALED) + fbuf_pos_x;
        end else begin
            fbuf_min_x <= 0;
            fbuf_min_y <= 0;
            fbuf_max_x <= 0;
            fbuf_max_y <= 0;
            fbuf_pos_x <= 0;
            fbuf_pos_y <= 0;
            char_min_x <= 0;
            char_min_y <= 0;
            char_max_x <= 0;
            char_max_y <= 0;
            char_pos_x <= 0;
            char_pos_y <= 0;
            fbuf_addr_int <= 0;
        end
    end
end


assign fbuf_en_wr = (state == BUSY_WRITE || state == BUSY_LASTWRITE) && character_row[char_pos_x];
assign fbuf_wrea = (state == BUSY_WRITE || state == BUSY_LASTWRITE) && character_row[char_pos_x];
assign fbuf_addr = (state == BUSY_WRITE || state == BUSY_LASTWRITE) && character_row[char_pos_x] ? fbuf_addr_int : 0;
assign fbuf_data = (state == BUSY_WRITE || state == BUSY_LASTWRITE) && character_row[char_pos_x] ? color_int : 0;

endmodule
