module cpu (
  input wire clk,
  input wire reset
);

  // data wires:
  wire [31:0] PC_in;
  wire [31:0] PC_out;

  wire [31:0] A_in;
  wire [31:0] A_out;
  wire [31:0] B_in;
  wire [31:0] B_out;

  wire [31:0] EPC_in;
  wire [31:0] EPC_out;

  wire [31:0] HI_in;
  wire [31:0] HI_out;

  wire [31:0] LO_in;
  wire [31:0] LO_out;

  wire [31:0] FLAG_REG_in;
  wire [31:0] FLAG_REG_out;

  wire [31:0] IR_in;
  wire [5:0] IR_opcode;
  wire [4:0] IR_rs;
  wire [4:0] IR_rt;
  wire [15:0] IR_im;      // im de imediato: address/immediate

  wire [4:0] ReadReg1;
  wire [4:0] ReadReg2;
  wire [4:0] WriteReg;
  wire [31:0] WriteDataReg;
  wire [31:0] ReadData1;
  wire [31:0] ReadData2;

  wire [31:0] Address;
  wire [31:0] WriteDataMem;
  wire [31:0] MemData;

  wire [4:0] SRN;
  wire [31:0] SRInput;
  wire [31:0] SROut;

  wire [31:0] ULA_out;

  // control wires:
  wire PC_write;

  wire A_write;
  wire B_write;

  wire A_write;
  wire B_write;

  wire EPC_write;

  wire HI_write;

  wire LO_write;

  wire FLAG_REG_write;

  wire IRWrite;

  wire RegWrite;

  wire MemWrite;

  wire [2:0] ShiftOP;

  wire [2:0] Seletor;

  // flags:
  wire Overflow; // O
  wire Negativo; // N
  wire Zero;  // Z
  wire Igual; // EG
  wire Maior; // GT
  wire Menor; // LT

  // Registradores
    Registrador PC_(
      clk,
      reset,
      PC_write,
      PC_in,
      PC_out
    );

    Registrador A_(
      clk,
      reset,
      A_write,
      A_in,
      A_out
    );

    Registrador B_(
      clk,
      reset,
      B_write,
      B_in,
      B_out
    );

    Registrador EPC_(
      clk,
      reset,
      EPC_write,
      EPC_in,
      EPC_out
    );

    Registrador HI_(
      clk,
      reset,
      HI_write,
      HI_in,
      HI_out
    );

    Registrador LO_(
      clk,
      reset,
      LO_write,
      LO_in,
      LO_out
    );

    Registrador FLAG_REG_(
      clk,
      reset,
      FLAG_REG_write,
      FLAG_REG_in,
      FLAG_REG_out
    );

    Instr_Reg IR_(
      clk,
      reset,
      IRWrite,
      IR_in,
      IR_opcode,
      IR_rs,
      IR_rt,
      IR_im
    );

    Banco_reg BANCO_REG_(
      clk,
      reset,
      RegWrite,
      ReadReg1,
      ReadReg2,
      WriteReg,
      WriteDataReg,
      ReadData1,
      ReadData2
    );

    RegDesloc SR(
      clk,
      reset,
      ShiftOP,
      SRN,
      SRInput,
      SROut
    );

  // memoria
  Memoria MEM_(
    Address,
    clk,
    MemWrite,
    WriteDataMem,
    MemData
  );

  // ULA
  ula32 ULA_(
    A_out,
    B_out,
    Seletor,
    ULA_out,
    Overflow,
    Negativo,
    Zero,
    Igual,
    Maior,
    Menor
  );

  // MUX
    //

endmodule
