module mux_wrReg (
  input wire [2:0] sel,
  input wire [4:0] inFromRT,
  input wire [4:0] inFromRD,
  // input const 31,
  // input const 29,
  input wire [4:0] inFromRS,
  output wire [4:0] out
);

  assign out =  (sel == 0) ? inFromRT :
                (sel == 1) ? inFromRD:
                (sel == 2) ? 31:
                (sel == 3) ? 29:
                inFromRS;

endmodule

