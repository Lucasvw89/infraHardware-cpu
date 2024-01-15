module mux_ulaA (
  input wire sel,
  input wire [31:0] inFromPC,
  input wire [31:0] inFromReg,
  output wire [31:0] out
);

  assign out = (sel == 0) ? inFromPC : inFromReg;

endmodule
