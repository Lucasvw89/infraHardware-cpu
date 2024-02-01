module load_size_control(
    input wire [1:0] load_size,
    input wire [31:0] load_input,
    output wire [23:0] out
);
    assign out = (load_size == 2'b00) ? load_input [7:0]:
    (load_size == 2'b01) ? load_input [15:0]:
    (load_size == 2'b10) ? load_input [31:16]:
    load_input [31:8];
endmodule