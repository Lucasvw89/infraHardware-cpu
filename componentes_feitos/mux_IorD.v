module mux_IorD (
  input wire [2:0] IorD,
  // input const 253,
  // input const 254,
  // input const 255,
  input wire [31:0] inFromPC,
  input wire [31:0] inFromALU,
  output wire [31:0] out
);

  assign out = (IorD == 0) ? 253 :
               (IorD == 1) ? 254 :
               (iorD == 2) ? 255 :
               (iorD == 3) ? inFromPC :
               inFromALU;

endmodule
