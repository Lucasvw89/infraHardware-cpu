module mux_SRInput (
  input wire SrInputSrc,
  input wire [31:0] inFromB,
  input wire [31:0] inFromA,
  output wire [31:0] out,
);

  assign out = (SrInputSrc == 0) ? inFromB : inFromA;

endmodule
