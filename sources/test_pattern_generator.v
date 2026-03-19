module test_pattern_generator #(
        parameter FRAME_WIDTH = 640,
        parameter FRAME_HEIGHT = 480,
        parameter SCALING_FACTOR = 1,
        parameter FBUF_ADDR_WIDTH = 19,
        parameter FBUF_DATA_WIDTH = 8
    ) (
        input wire clk,
        input wire rst_n,
        output reg [FBUF_ADDR_WIDTH - 1 : 0] pixel_fbuf_address,
        output reg [FBUF_DATA_WIDTH - 1 : 0] pixel_fbuf_color,
        output reg pixel_fbuf_wr_en,
        output wire pixel_fbuf_rst_req_n
    );
    
    assign pixel_fbuf_rst_req_n = rst_n;

    generate
        if (FBUF_DATA_WIDTH != 8) begin
            invalid_fbuf_data_width();
        end
    endgenerate

    reg [FBUF_ADDR_WIDTH - 1 : 0] address_counter;
    reg [12:0] pixel_x_counter;
    reg [12:0] pixel_y_counter;

    always @(posedge clk) begin
        if (!rst_n) begin
            address_counter <= 0;
            pixel_x_counter <= 0;
            pixel_y_counter <= 0;
        end else begin
            if (pixel_y_counter == FRAME_HEIGHT / SCALING_FACTOR - 1) begin
                address_counter <= 0;
                pixel_x_counter <= 0;
                pixel_y_counter <= 0;
            end else begin
                address_counter <= address_counter + 1;
                if (pixel_x_counter == FRAME_WIDTH / SCALING_FACTOR - 1) begin
                    pixel_x_counter <= 0;
                    pixel_y_counter <= pixel_y_counter + 1;
                end else begin
                    pixel_x_counter <= pixel_x_counter + 1;
                end
            end
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            pixel_fbuf_address <= 0;
            pixel_fbuf_color <= 0;
            pixel_fbuf_wr_en <= 0;
        end else begin
            pixel_fbuf_address <= address_counter;
            pixel_fbuf_wr_en <= 1;
            case ({pixel_x_counter[3], pixel_y_counter[3]})
                2'b00: pixel_fbuf_color <= 8'b11100000;
                2'b01: pixel_fbuf_color <= 8'b00011100;
                2'b10: pixel_fbuf_color <= 8'b00000011;
                2'b10: pixel_fbuf_color <= 8'b11111111;
            endcase
        end
    end

endmodule