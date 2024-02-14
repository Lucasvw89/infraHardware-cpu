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

  wire [31:0] FLAG_REG_in;    // nao vou deletar ainda, mas acho q podemos
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

  wire [31:0] ula_A_in;
  wire [31:0] ula_B_in;
  wire [31:0] ULA_out;

  wire [31:0] sign_extend_out;

  wire [31:0] shift_left_2_mux_ula_b_out;
  wire [31:0] shift_left_2_IR_out;

  wire [31:0] shift_16_out;

  wire [23:0] load_size_control_out;
  wire [31:0] store_size_control_out;

  wire conSrc_out;

  wire [31:0] mult_hi_out;
  wire [31:0] mult_lo_out;

  wire [31:0] div_hi_out;
  wire [31:0] div_lo_out;

  // control wires:
  wire PC_write;

  wire A_write;
  wire B_write;

  wire EPC_write;

  wire HI_write;

  wire LO_write;

  wire FlagRegWrite;

  wire IRWrite;

  // escrever no banco de registradores
  wire RegWrite;

  // mandar escrever na memoria
  wire MemWrite;

  // seletor de operacoes do Shift Register (SR)
  wire [2:0] ShiftOP;

  // seletor de operacoes da ULA
  wire [2:0] Seletor;

  wire mult_start;
  wire div_start;

  // MUX CONTROL WIRES
  wire seletor_ulaA;
  wire [1:0] seletor_ulaB;

  wire [2:0] RegDst;
  wire [3:0] MemtoReg;

  wire SrInputSrc;
  wire [1:0] SrNSrc;

  wire [1:0] load_size;
  wire store_size;

  wire SrctoMem;  // control wire to memory data source mux

  wire [2:0] IorD;
  wire [1:0] PCSource;
  wire [1:0] conSrc;
  wire HiLoSrc;

  wire writeCondition;

  // flags:
  wire Overflow; // O
  wire Negativo; // N
  wire Zero;  // Z
  wire Igual; // EG
  wire Maior; // GT
  wire Menor; // LT
  wire divzero; // divisao por zero

  // Registradores
    Registrador PC_(
      clk,
      reset,
      PC_write | (writeCondition & conSrc_out),
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
      FlagRegWrite,
      {29'b0, Igual, Menor, Maior},
      FLAG_REG_out
    );

    Instr_Reg IR_(
      clk,
      reset,
      IRWrite,
      MemData,
      IR_opcode,
      IR_rs,
      IR_rt,
      IR_im
    );

    Banco_reg BANCO_REG_(
      clk,
      reset,
      RegWrite,
      IR_rs,
      IR_rt,
      WriteReg,
      WriteDataReg,
      A_in,
      B_in
    );

    RegDesloc SR_(
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
    WriteDataMem, // datain
    MemData       // dataout
  );

  // ULA
  ula32 ULA_(
    ula_A_in,
    ula_B_in,
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
    mux_ulaA MUX_ULA_A_(
      seletor_ulaA,
      PC_out,
      A_out,
      ula_A_in
    );

    mux_ulaB MUX_ULA_B_(
      seletor_ulaB,
      B_out,
      // input const 4
      sign_extend_out,
      shift_left_2_mux_ula_b_out,
      ula_B_in
    );

    mux_wrReg MUX_WRREG_(
      RegDst,
      IR_rt,
      IR_im[15:11],
      IR_rs,
      WriteReg
    );

    mux_wrDataReg MUX_WRDATADATAREG_(
      MemtoReg,
      ULA_out,
      MemData,
      HI_out,
      LO_out,
      {{8'b0}, load_size_control_out},
      SROut,
      B_out,
      shift_16_out,
      A_out,
      {{31'b0}, {Menor}},
      WriteDataReg
    );

    mux_writeDataMemSrc MUX_WRITEDATAMEMSRC_(
      SrctoMem,
      B_out,
      store_size_control_out,
      WriteDataMem
    );

    mux_SRInput MUX_SRINPUT_(
      SrInputSrc,
      B_out,
      A_out,
      SRInput
    );

    mux_SRN MUX_SRN_(
      SrNSrc,
      IR_im[10:6],
      MemData[4:0],
      A_out[4:0],
      B_out[4:0],
      SRN
    );

    mux_IorD MUX_IORD_(
      IorD,
      PC_out,
      ULA_out,
      Address
    );

    mux_PcSrc MUX_PCSRC_(
      PCSource,
      ULA_out,
      {{PC_out[31:28]}, {shift_left_2_IR_out[27:0]}},
      {{8'b0}, load_size_control_out},
      EPC_out,
      PC_in
    );

    mux_conSrc MUX_CONSRC_(
      conSrc,
      FLAG_REG_out[2],
      ~FLAG_REG_out[2],
      FLAG_REG_out[2] | FLAG_REG_out[1],
      FLAG_REG_out[0],
      conSrc_out
    );

    mux_HILO MUX_HI_(
      HiLoSrc,
      div_hi_out,
      mult_hi_out,
      HI_in
    );

    mux_HILO MUX_LO_(
      HiLoSrc,
      div_lo_out,
      mult_lo_out,
      LO_in
    );

  // others:
  sign_extend SIGN_EXTEND_(
    IR_im,
    sign_extend_out
  );

  shift_left_2 SHIFT_LEFT_2_MUX_ULA_B_(
    sign_extend_out,
    shift_left_2_mux_ula_b_out
  );

  shift_left_2 SHIFT_LEFT_2_IR_(
    {6'b0, IR_rs, IR_rt, IR_im},
    shift_left_2_IR_out
  );

  shift_16 SHIFT_16_(
    IR_im,
    shift_16_out
  );

  load_size_control LOAD_SIZE_CONTROL_(
    load_size,
    MemData,
    load_size_control_out
  );

  store_size_control STORE_SIZE_CONTROL_(
    store_size,
    B_out,
    load_size_control_out,
    store_size_control_out
  );

  mult MULT_(
    A_out,
    B_out,
    clk,
    mult_start,
    reset,
    mult_hi_out,
    mult_lo_out
  );

  div DIV_(
    B_out,
    A_out,
    clk,
    div_start,
    reset,
    divzero,
    div_hi_out,
    div_lo_out
  );

  // control_unit
  control_unit CTRL_UNIT_(
    .clk(clk),
    .reset(reset),

    .Overflow(Overflow), // O
    .Negativo(Negativo), // N
    .Zero(Zero),  // Z
    .Igual(Igual), // EG
    .Maior(Maior), // GT
    .Menor(Menor), // LT
    .invalid_opcode(invalid_opcode),
    .divzero(divzero),

    .OPCODE(IR_opcode),
    .FUNCT(IR_im[5:0]),

    .conSrc_out(conSrc_out),

    .PC_write(PC_write),     
    .A_write(A_write),      
    .B_write(B_write),      
    .EPC_write(EPC_write),    
    .HI_write(HI_write),     
    .LO_write(LO_write),     
    .FlagRegWrite(FlagRegWrite), 
    .IRWrite(IRWrite),      
    .RegWrite(RegWrite),
    .MemWrite(MemWrite),
    .ShiftOP(ShiftOP),
    .Seletor(Seletor),
    .mult_start(mult_start), 
    .div_start(div_start),  
    .load_size(load_size),
    .store_size(store_size),
    .writeCondition(writeCondition),

    // mux control wires
    .seletor_ulaA(seletor_ulaA),
    .seletor_ulaB(seletor_ulaB),
    .RegDst(RegDst),   
    .MemtoReg(MemtoReg), 
    .SrInputSrc(SrInputSrc),
    .SrNSrc(SrNSrc),
    .SrctoMem(SrctoMem),
    .IorD(IorD),     
    .PCSource(PCSource), 
    .conSrc(conSrc),   
    .HiLoSrc(HiLoSrc),

   .reset_out(reset) 
  );

endmodule
