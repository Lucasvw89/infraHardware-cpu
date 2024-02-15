module mux_writeDataMemSrc (
  input wire WriteDataSrc,
  input wire [31:0] inFromB,
  input wire [31:0] inFromStoreSizeControl,
  output wire [31:0] out
);

  assign out = (WriteDataSrc == 0) ? inFromB : inFromStoreSizeControl;

endmodule
