module tb_axi4_lite_gpu_char_rom;

localparam CHAR_WIDTH = 8;
localparam CHAR_HEIGHT = 8;
localparam CHARACTER_COUNT = 8;

logic clk = 0;

logic en = 0;
logic [$clog2(CHARACTER_COUNT) - 1 : 0] char_code = 0;
logic [$clog2(CHAR_HEIGHT) - 1 : 0] char_row_addr = 0;
logic [CHAR_WIDTH - 1:0] char_row;

axi4_lite_gpu_char_rom #(
    .CHAR_WIDTH(CHAR_WIDTH),
    .CHAR_HEIGHT(CHAR_HEIGHT),
    .CHARACTER_COUNT(CHARACTER_COUNT)
) axi4_lite_gpu_char_rom_inst (
    .clk(clk),
    .en(en),
    .char_code(char_code),
    .char_row_addr(char_row_addr),
    .char_row(char_row)
);

always #5 clk = ~clk;

initial begin
    #10
    $display("ROM contents loaded from file");
    #10
    $finish();
end

endmodule
