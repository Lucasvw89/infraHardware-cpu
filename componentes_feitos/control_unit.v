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
  input wire [5:0] FUNCT,

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

    output reg mult_start,
    output reg div_start,

    output reg [1:0] load_size,
    output reg store_size,

    // MUX CONTROL WIRES
      output reg seletor_ulaA,
      output reg [1:0] seletor_ulaB,

      output reg [2:0] RegDst,
      output reg [3:0] MemtoReg,

      output reg SrInputSrc,
      output reg [1:0] SrNSrc,

      output reg SrctoMem,  // control wire to memory data source mux

      output reg [2:0] IorD,
      output reg [1:0] PCSource,
      output reg [1:0] conSrc,
      output reg HiLoSrc,

  output reg reset_out
);

  reg STATE; // TODO definir tamanho dessas variaveis
  reg COUNTER;

  // parameters:
  // R type instructions:
  parameter ST_r = 6'b0;

  // I type instructions:
  parameter ST_addi  = 6'b0;
  parameter ST_addiu = 6'b0; 
  parameter ST_beq   = 6'b0; 
  parameter ST_bne   = 6'b0; 
  parameter ST_ble   = 6'b0; 
  parameter ST_bgt   = 6'b0; 
  parameter ST_sram  = 6'b0; 
  parameter ST_lb    = 6'b0; 
  parameter ST_lh    = 6'b0; 
  parameter ST_lui   = 6'b0; 
  parameter ST_lw    = 6'b0; 
  parameter ST_sb    = 6'b0; 
  parameter ST_sh    = 6'b0; 
  parameter ST_slti  = 6'b0; 
  parameter ST_sw    = 6'b0; 

  // J type instructions:
  parameter ST_j = 6'b0;
  parameter ST_jal = 6'b0;

  // OPCODES and FUNCTS
  // R type instructions:
  parameter r = 6'b0;

  // I type instructions:
  parameter addi  = 6'b0;
  parameter addiu = 6'b0; 
  parameter beq   = 6'b0; 
  parameter bne   = 6'b0; 
  parameter ble   = 6'b0; 
  parameter bgt   = 6'b0; 
  parameter sram  = 6'b0; 
  parameter lb    = 6'b0; 
  parameter lh    = 6'b0; 
  parameter lui   = 6'b0; 
  parameter lw    = 6'b0; 
  parameter sb    = 6'b0; 
  parameter sh    = 6'b0; 
  parameter slti  = 6'b0; 
  parameter sw    = 6'b0; 

  // J type instructions:
  parameter j = 6'b0;
  parameter jal = 6'b0;

  // reset state:
  parameter reset = 6'b111111;

  initial begin
    reset_out = 1'b1;
  end

  always @ (posedge clk) begin
    if (reset == 1'b1) begin
      if (STATE != ST_reset) begin
        STATE = ST_reset;
        PC_write = 0;    
        A_write = 0;     
        B_write = 0;     
        EPC_write = 0;   
        HI_write = 0;    
        LO_write = 0;    
        FlagRegWrite = 0;
        IRWrite = 0;     
        RegWrite = 0;    
        MemWrite = 0;    
        ShiftOP = 0;     
        Seletor = 0;     

        reset_out = 1;

        counter = 0;

        // reset na pilha
        // TODO

      end else begin
        STATE = ST_common;
        PC_write = 0;    
        A_write = 0;     
        B_write = 0;     
        EPC_write = 0;   
        HI_write = 0;    
        LO_write = 0;    
        FlagRegWrite = 0;
        IRWrite = 0;     
        RegWrite = 0;    
        MemWrite = 0;    
        ShiftOP = 0;     
        Seletor = 0;     

        reset_out = 0;

        counter = 0;
      end
    end
  end

endmodule
