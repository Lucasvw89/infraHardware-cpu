module control_unit (
  // global signals
  input wire clk,
  input wire reset,

  // flags
  input wire Overflow, // O
  input wire Negativo, // N
  input wire Zero,  // Z
  input wire Igual, // EG
  input wire Maior, // GT
  input wire Menor, // LT

  // Opcode
  input wire [5:0] OPCODE,

  // control wires
    output reg PC_write,

    output reg A_write,
    output reg B_write,

    output reg EPC_write,

    output reg HI_write,

    output reg LO_write,

    output reg FlagRegWrite,

    output reg IRWrite,

    // escrever no banco de registradores
    output reg RegWrite,

    // escrever na memoria
    output reg MemWrite,

    // seletor de operacoes do Shift Register (SR)
    output reg [2:0] ShiftOP,

    // seletor de operacoes da ULA
    output reg [2:0] Seletor,

    // MUX CONTROL WIRES
      output reg seletor_ulaA,
      output reg [1:0] seletor_ulaB,

      output reg [2:0] RegDst,
      output reg [3:0] MemtoReg,

      output reg SrInputSrc,
      output reg [1:0] SrNSrc,

      output reg [1:0] load_size,
      output reg store_size,

      output reg SrctoMem,  // control wire to memory data source mux

      output reg [2:0] IorD,
      output reg [1:0] PCSource,
      output reg [1:0] conSrc,
      output reg HiLoSrc,

      output reg mult_start,
      output reg div_start,

  output reg reset
);

  // parametros:
    

  initial begin
    
  end

  always @ (posedge clk) begin
    
  end

endmodule
