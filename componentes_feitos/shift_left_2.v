module shift_left_2(
    input wire [31:0] in,
    output wire [31:0] out
);
    assign out = in << 2; // desloca o valor de in duas casas pra esquerda com zeros, ou seja, multiplica por 4

endmodule