module mux_wrDataReg (
  input wire [3:0] sel,
  input wire [31:0] inFromAluResult,
  input wire [31:0] inFromMemData,
  input wire [31:0] inFromHI,
  input wire [31:0] inFromLO,
  // input const 227
  input wire [31:0] inFromLoadSizeCtrl,
  input wire [31:0] inFromShiftReg,
  input wire [31:0] inFromB,
  input wire [31:0] inFromShift16,
  input wire [31:0] inFromA,
  input wire [31:0] inFromExtend,
  output wire [31:0] out
);

  assign out =  (sel == 0)  ? inFromAluResult:    
                (sel == 1)  ? inFromMemData:      
                (sel == 2)  ? inFromHI:           
                (sel == 3)  ? inFromLO:           
                (sel == 4)  ? 227:                 
                (sel == 5)  ? inFromLoadSizeCtrl: 
                (sel == 6)  ? inFromShiftReg:     
                (sel == 7)  ? inFromB:            
                (sel == 8)  ? inFromShift16:      
                (sel == 9)  ? inFromA:
                inFromExtend;

endmodule

