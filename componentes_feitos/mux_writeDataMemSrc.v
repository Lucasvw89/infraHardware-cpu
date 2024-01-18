module mux_writeDataMemSrc (
  input wire WriteDataSrc,
  input wire [31:0] inFromB,
  input wire [31:0] inFromStoreSizeControl,
  output wire [31:0] out
);

  assign out = (WriteDataSrc == 1) ? inFromB : inFromStoreSizeControl;

endmodule
