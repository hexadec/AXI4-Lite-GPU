module axi4_lite_gpu_char_rom #(
    parameter CHAR_WIDTH = 8,
    parameter CHAR_HEIGHT = 8,
    parameter CHARACTER_COUNT = 256
) (
    input clk,
    input en,
    input [$clog2(CHARACTER_COUNT) - 1 : 0] char_code,
    input [$clog2(CHAR_HEIGHT) - 1 : 0] char_row_addr,
    output logic [CHAR_WIDTH - 1:0] char_row
);

reg [CHAR_WIDTH - 1:0] rom [CHARACTER_COUNT * CHAR_HEIGHT - 1:0];

always @(posedge clk) begin
    if (en)  begin
        char_row <= rom[char_code * CHAR_HEIGHT + char_row_addr];
    end
end

initial begin
    $display("./font.mem");
    $readmemb("./font.mem", rom);
end

endmodule
