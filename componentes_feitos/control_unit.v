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

  reg [5:0] STATE;
  reg [5:0] COUNTER;

  // parameters:

  // R type instructions:
  parameter ST_r = 6'b0;

  // functs
  parameter ST_add   = 6'b000110;
  parameter ST_and   = 6'b000111;
  parameter ST_div   = 6'b001000;
  parameter ST_mult  = 6'b001001;
  parameter ST_jr    = 6'b001010;
  parameter ST_mfhi  = 6'b001011;
  parameter ST_mflo  = 6'b001100;
  parameter ST_sll   = 6'b001101;
  parameter ST_sllv  = 6'b001110;
  parameter ST_slt   = 6'b001111;
  parameter ST_sra   = 6'b010000;
  parameter ST_srav  = 6'b010001;
  parameter ST_srl   = 6'b010010;
  parameter ST_sub   = 6'b010011;
  parameter ST_break = 6'b010100;
  parameter ST_rte   = 6'b010101;
  parameter ST_xchg  = 6'b010110;


  // I type instructions:
  parameter ST_addi  = 6'b010111;
  parameter ST_addiu = 6'b011000;
  parameter ST_beq   = 6'b011001;
  parameter ST_bne   = 6'b011010;
  parameter ST_ble   = 6'b011011;
  parameter ST_bgt   = 6'b011100;
  parameter ST_sram  = 6'b011101;
  parameter ST_lb    = 6'b011110;
  parameter ST_lh    = 6'b011111;
  parameter ST_lui   = 6'b100000;
  parameter ST_lw    = 6'b100001;
  parameter ST_sb    = 6'b100010;
  parameter ST_sh    = 6'b100011;
  parameter ST_slti  = 6'b100100;
  parameter ST_sw    = 6'b100101;

  // J type instructions:
  parameter ST_j = 6'b000000;
  parameter ST_jal = 6'b000000;

  // OPCODES and FUNCTS
  // R type instructions:
  parameter opcode_r = 6'b000000;

  parameter funct_add   = 6'b100000;
  parameter funct_and   = 6'b100100;
  parameter funct_div   = 6'b011010;
  parameter funct_mult  = 6'b011000;
  parameter funct_jr    = 6'b001000;
  parameter funct_mfhi  = 6'b010000;
  parameter funct_mflo  = 6'b010010;
  parameter funct_sll   = 6'b000000;
  parameter funct_sllv  = 6'b000100;
  parameter funct_slt   = 6'b101010;
  parameter funct_sra   = 6'b000011;
  parameter funct_srav  = 6'b000111;
  parameter funct_srl   = 6'b000010;
  parameter funct_sub   = 6'b100010;
  parameter funct_break = 6'b001101;
  parameter funct_rte   = 6'b010011;
  parameter funct_xchg  = 6'b000101;

  // I type instructions:
  parameter opcode_addi  = 6'b001000;
  parameter opcode_addiu = 6'b001001; 
  parameter opcode_beq   = 6'b000100; 
  parameter opcode_bne   = 6'b000101; 
  parameter opcode_ble   = 6'b000110; 
  parameter opcode_bgt   = 6'b000111; 
  parameter opcode_sram  = 6'b000001; 
  parameter opcode_lb    = 6'b100000; 
  parameter opcode_lh    = 6'b100001; 
  parameter opcode_lui   = 6'b001111; 
  parameter opcode_lw    = 6'b100011; 
  parameter opcode_sb    = 6'b101000; 
  parameter opcode_sh    = 6'b101001; 
  parameter opcode_slti  = 6'b001010; 
  parameter opcode_sw    = 6'b101011; 

  // J type instructions:
  parameter opcode_j = 6'b000010;
  parameter opcode_jal = 6'b000011;

  // reset state:
  parameter ST_reset = 6'b111111;
  //common states
  parameter ST_fetch = 6'b000001;
  parameter ST_decode = 6'b000010;
  // error handling states
  parameter ST_invalid_opcode = 6'b000011;
  parameter ST_overflow = 6'b000100;
  parameter ST_divzero = 6'b000101;

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

    case(STATE) begin
      ADD:
        if (counter == 0)
    end
  end

endmodule
