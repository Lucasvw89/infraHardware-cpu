module mux_SRN (  // incompleto
  input wire [1:0] SrNSrc,
  input wire [4:0] inFromShamt,
  input wire [4:0] inFromMem,
  input wire [4:0] inFromA,
  input wire [4:0] inFromB,
  output wire [4:0] out,
);

  assign out =  (SrNSrc == 0) ? inFromShamt:
                (SrNSrc == 1) ? inFromMem:
                (SrNSrc == 2) ? inFromA:
                inFromB;

endmodule
