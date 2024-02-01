module mux_HILO (
  input HiLoSrc,
  input wire [31:0] inFromDiv,
  input wire [31:0] inFromMult,
  output wire [31:0] out
);

  assign out = (HiLoSrc == 0) ? inFromDiv : inFromMult;

endmodule
