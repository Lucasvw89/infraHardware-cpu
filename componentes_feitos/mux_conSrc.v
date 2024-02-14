module mux_conSrc (
  input wire [1:0] conSrc,
  input wire equalTo,
  input wire notEqualTo,
  input wire lessThanOrEq,
  input wire moreThan,
  output wire out
);

  assign out =  (conSrc == 0) ? equalTo :
                (conSrc == 1) ? notEqualTo:
                (conSrc == 2) ? lessThanOrEq:
                moreThan;

endmodule
