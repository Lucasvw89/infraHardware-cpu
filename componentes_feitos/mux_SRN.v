module mux_SRInput (  // incompleto
  input wire [1:0] SrInputSrc,
  input wire [4:0] inFromShamt,
  input wire [31:0] inFromMem,
  input wire [4:0] inFromA,
  input wire [4:0] inFromA,
  output wire [4:0] out,
);

  assign out = (SrInputSrc == 0) ? inFromB : inFromA;

endmodule
