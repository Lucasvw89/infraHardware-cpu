module mux_PcSrc (
  input wire [1:0] sel,
  input wire [31:0] inFromALU, 
  input wire [31:0] inFromShiftL2,
  input wire [31:0] inFromLoadSizeControl,
  input wire [31:0] inFromEPC,
  output wire [31:0] out
);

  assign out =  (sel == 0) ? inFromALU :
                (sel == 1) ? inFromShiftL2:
                (sel == 2) ? inFromLoadSizeControl:
                inFromEPC;

endmodule
