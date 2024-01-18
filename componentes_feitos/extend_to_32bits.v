module extend_to_32bits (
  input wire [31:0] in, // pode variar de 1 a 16 bits, n sei se funciona.
  output wire [31:0] out
);

  assign out = in;

endmodule
