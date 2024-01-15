module mux_ulaB (
  input wire [1:0] sel,
  input wire [31:0] inFromReg,
  // input const 4
  input wire [31:0] inFromSignExt,
  input wire [31:0] inFromShiftL2,
  output wire [31:0] out
);

  assign out =  (sel == 0) ? inFromReg :
                (sel == 1) ? 4:
                (sel == 2) ? inFromSignExt:
                inFromShiftL2;

endmodule
