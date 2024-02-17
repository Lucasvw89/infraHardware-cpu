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
  input wire invalid_opcode,
  input wire divzero,

  // Opcode
  input wire [5:0] OPCODE,
  input wire [5:0] FUNCT,

  // PC_write condition
  input wire conSrc_out,

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

    output reg writeCondition,

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

  // to deal with overflow
  reg CAN_OVERFLOW;

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
  parameter ST_j = 6'b100110;
  parameter ST_jal = 6'b100111;

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

  // reset STATE:
  parameter ST_reset = 6'b111111;
  //common STATEs
  parameter ST_fetch = 6'b000001;
  parameter ST_decode = 6'b000010;    // meio inutil aqui
  parameter ST_shift_end = 6'b101100;
  parameter ST_conditional_branch = 6'b101101;
  // error handling STATEs
  parameter ST_invalid_opcode = 6'b000011;
  parameter ST_overflow = 6'b000100;
  parameter ST_divzero = 6'b000101;

  initial begin
    reset_out = 1'b1;
    STATE = ST_fetch;
  end

  always @ (posedge clk) begin
    if (reset_out == 1'b1) begin
      if (STATE !== ST_reset) begin    // de qualquer valor pro reset
        STATE = ST_reset;
        PC_write = 0;    
        writeCondition = 0;
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
        mult_start = 0; 
        div_start = 0;  
        load_size = 0;
        store_size = 0;

        seletor_ulaA = 0;
        seletor_ulaB = 0;
        RegDst = 0;   
        MemtoReg = 0; 
        SrInputSrc = 0;
        SrNSrc = 0;
        SrctoMem = 0;
        IorD = 0;     
        PCSource = 0; 
        conSrc = 0;   
        HiLoSrc = 0;

        reset_out = 1;

        COUNTER = 0;

      end else begin      // state reset reseta a pilha
        STATE = ST_fetch;
        PC_write = 0;    
        writeCondition = 0;
        A_write = 0;     
        B_write = 0;     
        EPC_write = 0;   
        HI_write = 0;    
        LO_write = 0;    
        FlagRegWrite = 0;
        IRWrite = 0;     
        RegWrite = 1'b1;    //
        MemWrite = 0;    
        ShiftOP = 0;     
        Seletor = 0;     
        mult_start = 0; 
        div_start = 0;  
        load_size = 0;
        store_size = 0;

        seletor_ulaA = 0;
        seletor_ulaB = 0;
        RegDst = 3'b011;   //
        MemtoReg = 4'b0100; //
        SrInputSrc = 0;
        SrNSrc = 0;
        SrctoMem = 0;
        IorD = 0;     
        PCSource = 0; 
        conSrc = 0;   
        HiLoSrc = 0;

        reset_out = 0; //*

        COUNTER = 0;
      end
    end
    else begin
      case (STATE)
        ST_fetch: begin
          if(COUNTER <= 6'b000001) begin //talvez mude

            STATE = ST_fetch; //*

            PC_write = 1'b0;    
            writeCondition = 0;
            A_write = 1'b0;     
            B_write = 1'b0;     
            EPC_write = 1'b0;   
            HI_write = 1'b0;    
            LO_write = 1'b0;    
            FlagRegWrite = 1'b0;
            IRWrite = 1'b0;     
            RegWrite = 1'b0;    
            MemWrite = 1'b0; //*  
            ShiftOP = 0;     
            Seletor = 3'b0;     
            mult_start = 1'b0; 
            div_start = 1'b0;  
            load_size = 2'b0;
            store_size = 1'b0;

            seletor_ulaA = 1'b0;
            seletor_ulaB = 2'b0;
            RegDst = 4'b0;   
            MemtoReg = 4'b0; 
            SrInputSrc = 1'b0;
            SrNSrc = 3'b0;
            SrctoMem = 0;
            IorD = 3'b011; //* 
            PCSource = 2'b0; 
            conSrc = 0;   
            HiLoSrc = 1'b0;

            reset_out = 1'b0; //*

            COUNTER = COUNTER + 1;

            if (Overflow == 1'b1 && CAN_OVERFLOW == 1'b1)begin
              STATE = ST_overflow;
              CAN_OVERFLOW = 0;
              COUNTER = 0;
            end

          end else if(COUNTER == 6'b000010)begin

            STATE = ST_fetch;

            PCSource = 2'b00; //*
            seletor_ulaA = 1'b0; //*
            seletor_ulaB = 2'b01; //*
            Seletor = 3'b001; //*
            PC_write = 1'b1; //*
            IRWrite = 1'b1; //* 

            COUNTER = COUNTER + 1;

            CAN_OVERFLOW = 0;

          end
          else if(COUNTER == 6'b000011) begin
            STATE = ST_fetch;

            IRWrite = 1'b0; //* 
            PC_write = 1'b0; //*
            A_write = 1'b1; //*
            B_write = 1'b1; //*

            COUNTER = COUNTER + 1;
          end

        else if(COUNTER == 6'b000100)begin
            A_write = 1'b0; //*
            B_write = 1'b0; //*
            COUNTER = 6'b0;

            case(OPCODE)

              opcode_r: begin

                case(FUNCT)

                  funct_add: begin
                    STATE = ST_add;
                  end
                  funct_and: begin
                    STATE = ST_and;
                  end
                  funct_div: begin
                    STATE = ST_div;
                  end
                  funct_mult: begin
                    STATE = ST_mult;
                  end
                  funct_jr: begin
                    STATE = ST_jr;
                  end
                  funct_mfhi: begin
                    STATE = ST_mfhi;
                  end
                  funct_mflo: begin
                    STATE = ST_mflo;
                  end
                  funct_sll: begin
                    STATE = ST_sll;
                  end
                  funct_sllv: begin
                    STATE = ST_sllv;
                  end
                  funct_slt: begin
                    STATE = ST_slt;
                  end
                  funct_sra: begin
                    STATE = ST_sra;
                  end
                  funct_srav: begin
                    STATE = ST_srav;
                  end
                  funct_srl: begin
                    STATE = ST_srl;
                  end
                  funct_sub: begin
                    STATE = ST_sub;
                  end
                  funct_break: begin
                    STATE = ST_break;
                  end
                  funct_rte: begin
                    STATE = ST_rte;
                  end
                  funct_xchg: begin
                    STATE = ST_xchg;
                  end
                  default: begin
                    STATE = ST_invalid_opcode;
                  end

                endcase

              end

            opcode_addi: begin
              STATE = ST_addi;
            end
            opcode_addiu: begin
              STATE = ST_addiu;
            end
            opcode_beq: begin
              STATE = ST_conditional_branch;
            end
            opcode_bne: begin
              STATE = ST_conditional_branch;
            end
            opcode_ble: begin
              STATE = ST_conditional_branch;
            end
            opcode_bgt: begin
              STATE = ST_conditional_branch;
            end
            opcode_sram: begin
              STATE = ST_sram;
            end
            opcode_lb: begin
              STATE = ST_lb;
            end
            opcode_lh: begin
              STATE = ST_lh;
            end
            opcode_lui: begin
              STATE = ST_lui;
            end
            opcode_lw: begin
              STATE = ST_lw;
            end
            opcode_sb: begin
              STATE = ST_sb;
            end
            opcode_sh: begin
              STATE = ST_sh;
            end
            opcode_slti: begin
              STATE = ST_slti;
            end
            opcode_sw: begin
              STATE = ST_sw;
            end
            opcode_j: begin
              STATE = ST_j;
            end
            opcode_jal: begin
              STATE = ST_jal;
            end
            default: begin
              STATE = ST_invalid_opcode;
            end

          endcase
          end
        end

        ST_add: begin
          STATE = ST_fetch;
          PC_write = 1'b0;  
          A_write = 1'b0;     
          B_write = 1'b0;     
          EPC_write = 1'b0;   
          HI_write = 1'b0;    
          LO_write = 1'b0;    
          FlagRegWrite = 1'b0;
          IRWrite = 1'b0;     
          RegWrite = 1'b1;  //*  
          MemWrite = 1'b0;   
          ShiftOP = 0;     
          Seletor = 3'b001; //*     
          mult_start = 1'b0; 
          div_start = 1'b0;  
          load_size = 2'b0;
          store_size = 1'b0;

          seletor_ulaA = 1'b1; //*
          seletor_ulaB = 2'b00; //*
          RegDst = 3'b001; //*
          MemtoReg = 4'b0; //*
          SrInputSrc = 1'b0;
          SrNSrc = 3'b0;
          SrctoMem = 0;
          IorD = 3'b000; 
          PCSource = 2'b00;
          conSrc = 0;   
          HiLoSrc = 1'b0;

          reset_out = 1'b0; 

          CAN_OVERFLOW = 1'b1;

        end

        ST_and: begin
          PC_write = 1'b0;    
          A_write = 1'b0;     
          B_write = 1'b0;     
          EPC_write = 1'b0;   
          HI_write = 1'b0;    
          LO_write = 1'b0;    
          FlagRegWrite = 1'b0;
          IRWrite = 1'b0;     
          RegWrite = 1'b1; //*
          MemWrite = 1'b0;   
          ShiftOP = 0;     
          Seletor = 3'b011;  //*
          mult_start = 1'b0; 
          div_start = 1'b0;  
          load_size = 2'b0;
          store_size = 1'b0;

          seletor_ulaA = 1'b1; //*
          seletor_ulaB = 2'b00; //*
          RegDst = 3'b001; //*
          MemtoReg = 4'b0; //*
          SrInputSrc = 1'b0;
          SrNSrc = 3'b0;
          SrctoMem = 0;
          IorD = 3'b000; 
          PCSource = 2'b00;
          conSrc = 0;   
          HiLoSrc = 1'b0;

          reset_out = 1'b0; 
          STATE = ST_fetch;
        end

        ST_div: begin
          if (COUNTER == 0) begin
            STATE = ST_div;

            PC_write = 1'b0;
            A_write = 1'b0;     
            B_write = 1'b0;     
            EPC_write = 1'b0;   
            HI_write = 1'b0;    
            LO_write = 1'b0;    
            FlagRegWrite = 1'b0;
            IRWrite = 1'b0;     
            RegWrite = 1'b0;
            MemWrite = 1'b0;   
            ShiftOP = 0;     
            Seletor = 3'b0;     
            mult_start = 1'b0; 
            div_start = 1'b1;   //
            load_size = 2'b0;
            store_size = 1'b0;

            seletor_ulaA = 1'b0;
            seletor_ulaB = 2'b0;
            RegDst = 3'b000;
            MemtoReg = 4'b0; 
            SrInputSrc = 1'b0;
            SrNSrc = 3'b0;
            SrctoMem = 0;
            IorD = 3'b000; 
            PCSource = 2'b01;
            conSrc = 0;   
            HiLoSrc = 1'b0;

            reset_out = 1'b0; 

            COUNTER = COUNTER + 1;

          end else if (COUNTER < 32) begin
            STATE = ST_div;
            div_start = 1'b0;   //
            COUNTER = COUNTER + 1;
            if (divzero == 1) begin
              STATE = ST_divzero;
              COUNTER = 0;
            end
          end else begin
            STATE = ST_fetch;

            HiLoSrc = 1'b0;
            HI_write = 1'b1;
            LO_write = 1'b1;

            COUNTER = 0;
          end
        end

        ST_mult: begin
          if (COUNTER == 0) begin
            STATE = ST_mult;
            PC_write = 1'b0;
            A_write = 1'b0;     
            B_write = 1'b0;     
            EPC_write = 1'b0;   
            HI_write = 1'b0;    
            LO_write = 1'b0;    
            FlagRegWrite = 1'b0;
            IRWrite = 1'b0;     
            RegWrite = 1'b0;
            MemWrite = 1'b0;   
            ShiftOP = 0;     
            Seletor = 3'b0;     
            mult_start = 1'b1;  //
            div_start = 1'b0;  
            load_size = 2'b0;
            store_size = 1'b0;

            seletor_ulaA = 1'b0;
            seletor_ulaB = 2'b0;
            RegDst = 3'b000;
            MemtoReg = 4'b0; 
            SrInputSrc = 1'b0;
            SrNSrc = 3'b0;
            SrctoMem = 0;
            IorD = 3'b000; 
            PCSource = 2'b00;
            conSrc = 0;   
            HiLoSrc = 1'b1;

            reset_out = 1'b0; 

            COUNTER = COUNTER + 1;
          end else if (COUNTER < 32) begin
            STATE = ST_mult;
            mult_start = 1'b0;  //
            COUNTER = COUNTER + 1;
          end else begin
            STATE = ST_fetch;

            HiLoSrc = 1'b1;
            HI_write = 1'b1;
            LO_write = 1'b1;

            COUNTER = 0;
          end
        end

        ST_jr: begin
          STATE = ST_fetch;

          PC_write = 1'b1;      //
          A_write = 1'b0;     
          B_write = 1'b0;     
          EPC_write = 1'b0;   
          HI_write = 1'b0;    
          LO_write = 1'b0;    
          FlagRegWrite = 1'b0;
          IRWrite = 1'b0;     
          RegWrite = 1'b0;    
          MemWrite = 1'b0;
          ShiftOP = 0;     
          Seletor = 3'b000;       //
          mult_start = 1'b0; 
          div_start = 1'b0;  
          load_size = 2'b0;
          store_size = 1'b0;

          seletor_ulaA = 1'b1;   //
          seletor_ulaB = 2'b0;
          RegDst = 4'b0;   
          MemtoReg = 4'b0; 
          SrInputSrc = 1'b0;
          SrNSrc = 3'b0;
          SrctoMem = 0;
          IorD = 3'b011; 
          PCSource = 2'b00;     //
          conSrc = 0;   
          HiLoSrc = 1'b0;

          reset_out = 1'b0;
        end

        ST_mfhi: begin
          PC_write = 1'b0;    
          A_write = 1'b0;     
          B_write = 1'b0;     
          EPC_write = 1'b0;   
          HI_write = 1'b0;    
          LO_write = 1'b0;    
          FlagRegWrite = 1'b0;
          IRWrite = 1'b0;     
          RegWrite = 1'b1; //* 
          MemWrite = 1'b0;   
          ShiftOP = 0;     
          Seletor = 3'b0;     
          mult_start = 1'b0; 
          div_start = 1'b0;  
          load_size = 2'b0;
          store_size = 1'b0;

          seletor_ulaA = 1'b0;
          seletor_ulaB = 2'b0;
          RegDst = 3'b001; //*
          MemtoReg = 4'b0010; //*
          SrInputSrc = 1'b0;
          SrNSrc = 3'b0;
          SrctoMem = 0;
          IorD = 3'b000; 
          PCSource = 2'b0; 
          conSrc = 0;   
          HiLoSrc = 1'b0;

          reset_out = 1'b0; 
          STATE = ST_fetch;
        end

        ST_mflo: begin
          PC_write = 1'b0;   
          A_write = 1'b0;     
          B_write = 1'b0;     
          EPC_write = 1'b0;   
          HI_write = 1'b0;    
          LO_write = 1'b0;    
          FlagRegWrite = 1'b0;
          IRWrite = 1'b0;     
          RegWrite = 1'b1; //*  
          MemWrite = 1'b0;   
          ShiftOP = 0;     
          Seletor = 3'b0;     
          mult_start = 1'b0; 
          div_start = 1'b0;  
          load_size = 2'b0;
          store_size = 1'b0;

          seletor_ulaA = 1'b0;
          seletor_ulaB = 2'b0;
          RegDst = 3'b001; //*
          MemtoReg = 4'b0011; //*
          SrInputSrc = 1'b0;
          SrNSrc = 3'b0;
          SrctoMem = 0;
          IorD = 3'b000; 
          PCSource = 2'b00; 
          conSrc = 0;   
          HiLoSrc = 1'b0;

          reset_out = 1'b0; 
          STATE = ST_fetch;
        end

        ST_sll: begin

        if(COUNTER == 6'b0)begin

          PC_write = 1'b0;   
          A_write = 1'b0;     
          B_write = 1'b0;     
          EPC_write = 1'b0;   
          HI_write = 1'b0;    
          LO_write = 1'b0;    
          FlagRegWrite = 1'b0;
          IRWrite = 1'b0;     
          RegWrite = 1'b0; 
          MemWrite = 1'b0;   
          ShiftOP = 3'b001; //*    
          Seletor = 3'b0;     
          mult_start = 1'b0; 
          div_start = 1'b0;  
          load_size = 2'b0;
          store_size = 1'b0;

          seletor_ulaA = 1'b0;
          seletor_ulaB = 2'b0;
          RegDst = 3'b000;
          MemtoReg = 4'b0000;
          SrInputSrc = 1'b0; //*
          SrNSrc = 3'b000; //*
          SrctoMem = 0;
          IorD = 3'b000; 
          PCSource = 2'b00; 
          conSrc = 0;   
          HiLoSrc = 1'b0;

          reset_out = 1'b0; 
          STATE = ST_sll;
          COUNTER = COUNTER + 1;
        end
        else begin
          PC_write = 1'b0;   
          A_write = 1'b0;     
          B_write = 1'b0;     
          EPC_write = 1'b0;   
          HI_write = 1'b0;    
          LO_write = 1'b0;    
          FlagRegWrite = 1'b0;
          IRWrite = 1'b0;     
          RegWrite = 1'b0; 
          MemWrite = 1'b0;   
          ShiftOP = 3'b010; //*    
          Seletor = 3'b0;     
          mult_start = 1'b0; 
          div_start = 1'b0;  
          load_size = 2'b0;
          store_size = 1'b0;

          seletor_ulaA = 1'b0;
          seletor_ulaB = 2'b0;
          RegDst = 3'b000;
          MemtoReg = 4'b0000;
          SrInputSrc = 1'b0;
          SrNSrc = 3'b000;
          SrctoMem = 0;
          IorD = 3'b000; 
          PCSource = 2'b00; 
          conSrc = 0;   
          HiLoSrc = 1'b0;

          reset_out = 1'b0; 
          STATE = ST_shift_end;      
        end
      end

        ST_sllv: begin

        if(COUNTER == 6'b0)begin

          PC_write = 1'b0;   
          A_write = 1'b0;     
          B_write = 1'b0;     
          EPC_write = 1'b0;   
          HI_write = 1'b0;    
          LO_write = 1'b0;    
          FlagRegWrite = 1'b0;
          IRWrite = 1'b0;     
          RegWrite = 1'b0; 
          MemWrite = 1'b0;   
          ShiftOP = 3'b001; //*    
          Seletor = 3'b0;     
          mult_start = 1'b0; 
          div_start = 1'b0;  
          load_size = 2'b0;
          store_size = 1'b0;

          seletor_ulaA = 1'b0;
          seletor_ulaB = 2'b0;
          RegDst = 3'b000;
          MemtoReg = 4'b0000;
          SrInputSrc = 1'b1; //*
          SrNSrc = 3'b011; //*
          SrctoMem = 0;
          IorD = 3'b000; 
          PCSource = 2'b00; 
          conSrc = 0;   
          HiLoSrc = 1'b0;

          reset_out = 1'b0; 
          STATE = ST_sllv;
          COUNTER = COUNTER + 1;
        end
        else begin
          PC_write = 1'b0;   
          A_write = 1'b0;     
          B_write = 1'b0;     
          EPC_write = 1'b0;   
          HI_write = 1'b0;    
          LO_write = 1'b0;    
          FlagRegWrite = 1'b0;
          IRWrite = 1'b0;     
          RegWrite = 1'b0; 
          MemWrite = 1'b0;   
          ShiftOP = 3'b010; //*    
          Seletor = 3'b0;     
          mult_start = 1'b0; 
          div_start = 1'b0;  
          load_size = 2'b0;
          store_size = 1'b0;

          seletor_ulaA = 1'b0;
          seletor_ulaB = 2'b0;
          RegDst = 3'b000;
          MemtoReg = 4'b0000;
          SrInputSrc = 1'b0;
          SrNSrc = 3'b000;
          SrctoMem = 0;
          IorD = 3'b000; 
          PCSource = 2'b00; 
          conSrc = 0;   
          HiLoSrc = 1'b0;

          reset_out = 1'b0; 
          STATE = ST_shift_end;      
        end
      end 

        ST_slt: begin
          PC_write = 1'b0;    
          A_write = 1'b0;     
          B_write = 1'b0;     
          EPC_write = 1'b0;   
          HI_write = 1'b0;    
          LO_write = 1'b0;    
          FlagRegWrite = 1'b0;
          IRWrite = 1'b0;     
          RegWrite = 1'b1; //*
          MemWrite = 1'b0;   
          ShiftOP = 0;     
          Seletor = 3'b111; //*
          mult_start = 1'b0; 
          div_start = 1'b0;  
          load_size = 2'b0;
          store_size = 1'b0;

          seletor_ulaA = 1'b1; //*
          seletor_ulaB = 2'b00; //*
          RegDst = 3'b001; //*
          MemtoReg = 4'b1010; //*
          SrInputSrc = 1'b0;
          SrNSrc = 3'b0;
          SrctoMem = 0;
          IorD = 3'b000; 
          PCSource = 2'b00;
          conSrc = 0;   
          HiLoSrc = 1'b0;

          reset_out = 1'b0; 

          STATE = ST_fetch;
        end

        ST_sra: begin

        if(COUNTER == 6'b0)begin

          PC_write = 1'b0;   
          A_write = 1'b0;     
          B_write = 1'b0;     
          EPC_write = 1'b0;   
          HI_write = 1'b0;    
          LO_write = 1'b0;    
          FlagRegWrite = 1'b0;
          IRWrite = 1'b0;     
          RegWrite = 1'b0; 
          MemWrite = 1'b0;   
          ShiftOP = 3'b001; //*    
          Seletor = 3'b0;     
          mult_start = 1'b0; 
          div_start = 1'b0;  
          load_size = 2'b0;
          store_size = 1'b0;

          seletor_ulaA = 1'b0;
          seletor_ulaB = 2'b0;
          RegDst = 3'b000;
          MemtoReg = 4'b0000;
          SrInputSrc = 1'b0; //*
          SrNSrc = 3'b000; //*
          SrctoMem = 0;
          IorD = 3'b000; 
          PCSource = 2'b00; 
          conSrc = 0;   
          HiLoSrc = 1'b0;

          reset_out = 1'b0; 
          STATE = ST_sra;
          COUNTER = COUNTER + 1;
        end
        else begin
          PC_write = 1'b0;   
          A_write = 1'b0;     
          B_write = 1'b0;     
          EPC_write = 1'b0;   
          HI_write = 1'b0;    
          LO_write = 1'b0;    
          FlagRegWrite = 1'b0;
          IRWrite = 1'b0;     
          RegWrite = 1'b0; 
          MemWrite = 1'b0;   
          ShiftOP = 3'b100; //*    
          Seletor = 3'b0;     
          mult_start = 1'b0; 
          div_start = 1'b0;  
          load_size = 2'b0;
          store_size = 1'b0;

          seletor_ulaA = 1'b0;
          seletor_ulaB = 2'b0;
          RegDst = 3'b000;
          MemtoReg = 4'b0000;
          SrInputSrc = 1'b0;
          SrNSrc = 3'b000;
          SrctoMem = 0;
          IorD = 3'b000; 
          PCSource = 2'b00; 
          conSrc = 0;   
          HiLoSrc = 1'b0;

          reset_out = 1'b0; 
          STATE = ST_shift_end;      
        end
      end

        ST_srav: begin

        if(COUNTER == 6'b0)begin

          PC_write = 1'b0;   
          A_write = 1'b0;     
          B_write = 1'b0;     
          EPC_write = 1'b0;   
          HI_write = 1'b0;    
          LO_write = 1'b0;    
          FlagRegWrite = 1'b0;
          IRWrite = 1'b0;     
          RegWrite = 1'b0; 
          MemWrite = 1'b0;   
          ShiftOP = 3'b001; //*    
          Seletor = 3'b0;     
          mult_start = 1'b0; 
          div_start = 1'b0;  
          load_size = 2'b0;
          store_size = 1'b0;

          seletor_ulaA = 1'b0;
          seletor_ulaB = 2'b0;
          RegDst = 3'b000;
          MemtoReg = 4'b0000;
          SrInputSrc = 1'b1; //*
          SrNSrc = 3'b011; //*
          SrctoMem = 0;
          IorD = 3'b000; 
          PCSource = 2'b00; 
          conSrc = 0;   
          HiLoSrc = 1'b0;

          reset_out = 1'b0; 
          STATE = ST_srav;
          COUNTER = COUNTER + 1;
        end
        else begin
          PC_write = 1'b0;   
          A_write = 1'b0;     
          B_write = 1'b0;     
          EPC_write = 1'b0;   
          HI_write = 1'b0;    
          LO_write = 1'b0;    
          FlagRegWrite = 1'b0;
          IRWrite = 1'b0;     
          RegWrite = 1'b0; 
          MemWrite = 1'b0;   
          ShiftOP = 3'b100; //*    
          Seletor = 3'b0;     
          mult_start = 1'b0; 
          div_start = 1'b0;  
          load_size = 2'b0;
          store_size = 1'b0;

          seletor_ulaA = 1'b0;
          seletor_ulaB = 2'b0;
          RegDst = 3'b000;
          MemtoReg = 4'b0000;
          SrInputSrc = 1'b0;
          SrNSrc = 3'b000;
          SrctoMem = 0;
          IorD = 3'b000; 
          PCSource = 2'b00; 
          conSrc = 0;   
          HiLoSrc = 1'b0;

          reset_out = 1'b0; 
          STATE = ST_shift_end;      
        end
      end

        ST_srl: begin

        if(COUNTER == 6'b0)begin

          PC_write = 1'b0;   
          A_write = 1'b0;     
          B_write = 1'b0;     
          EPC_write = 1'b0;   
          HI_write = 1'b0;    
          LO_write = 1'b0;    
          FlagRegWrite = 1'b0;
          IRWrite = 1'b0;     
          RegWrite = 1'b0; 
          MemWrite = 1'b0;   
          ShiftOP = 3'b001; //*    
          Seletor = 3'b0;     
          mult_start = 1'b0; 
          div_start = 1'b0;  
          load_size = 2'b0;
          store_size = 1'b0;

          seletor_ulaA = 1'b0;
          seletor_ulaB = 2'b0;
          RegDst = 3'b000;
          MemtoReg = 4'b0000;
          SrInputSrc = 1'b0; //*
          SrNSrc = 3'b000; //*
          SrctoMem = 0;
          IorD = 3'b000; 
          PCSource = 2'b00; 
          conSrc = 0;   
          HiLoSrc = 1'b0;

          reset_out = 1'b0; 
          STATE = ST_srl;
          COUNTER = COUNTER + 1;
        end
        else begin
          PC_write = 1'b0;   
          A_write = 1'b0;     
          B_write = 1'b0;     
          EPC_write = 1'b0;   
          HI_write = 1'b0;    
          LO_write = 1'b0;    
          FlagRegWrite = 1'b0;
          IRWrite = 1'b0;     
          RegWrite = 1'b0; 
          MemWrite = 1'b0;   
          ShiftOP = 3'b011; //*    
          Seletor = 3'b0;     
          mult_start = 1'b0; 
          div_start = 1'b0;  
          load_size = 2'b0;
          store_size = 1'b0;

          seletor_ulaA = 1'b0;
          seletor_ulaB = 2'b0;
          RegDst = 3'b000;
          MemtoReg = 4'b0000;
          SrInputSrc = 1'b0;
          SrNSrc = 3'b000;
          SrctoMem = 0;
          IorD = 3'b000; 
          PCSource = 2'b00; 
          conSrc = 0;   
          HiLoSrc = 1'b0;

          reset_out = 1'b0; 
          STATE = ST_shift_end;      
        end
      end

        ST_shift_end: begin
          PC_write = 1'b0;   
          A_write = 1'b0;     
          B_write = 1'b0;     
          EPC_write = 1'b0;   
          HI_write = 1'b0;    
          LO_write = 1'b0;    
          FlagRegWrite = 1'b0;
          IRWrite = 1'b0;     
          RegWrite = 1'b1;  //*  
          MemWrite = 1'b0;   
          ShiftOP = 0;     
          Seletor = 3'b0;     
          mult_start = 1'b0; 
          div_start = 1'b0;  
          load_size = 2'b0;
          store_size = 1'b0;

          seletor_ulaA = 1'b0;
          seletor_ulaB = 2'b0;
          RegDst = 3'b001; //*
          MemtoReg = 4'b0110; //*
          SrInputSrc = 1'b0;
          SrNSrc = 3'b0;
          SrctoMem = 0;
          IorD = 3'b000; 
          PCSource = 2'b00; 
          conSrc = 0;   
          HiLoSrc = 1'b0;

          reset_out = 1'b0; 
          STATE = ST_fetch;

          COUNTER = 0;

      end

        ST_sub: begin
          STATE = ST_fetch;
          PC_write = 1'b0;  
          A_write = 1'b0;     
          B_write = 1'b0;     
          EPC_write = 1'b0;   
          HI_write = 1'b0;    
          LO_write = 1'b0;    
          FlagRegWrite = 1'b0;
          IRWrite = 1'b0;     
          RegWrite = 1'b1;  //*  
          MemWrite = 1'b0;   
          ShiftOP = 0;     
          Seletor = 3'b010; //*     
          mult_start = 1'b0; 
          div_start = 1'b0;  
          load_size = 2'b0;
          store_size = 1'b0;

          seletor_ulaA = 1'b1; //*
          seletor_ulaB = 2'b00; //*
          RegDst = 3'b001; //*
          MemtoReg = 4'b0000; //* 
          SrInputSrc = 1'b0;
          SrNSrc = 3'b0;
          SrctoMem = 0;
          IorD = 3'b000; 
          PCSource = 2'b00;
          conSrc = 0;   
          HiLoSrc = 1'b0;
          reset_out = 1'b0; 

          CAN_OVERFLOW = 1'b1;

        end

        ST_break: begin
          STATE = ST_fetch;

          PC_write = 1'b1;      //
          A_write = 1'b0;     
          B_write = 1'b0;     
          EPC_write = 1'b0;   
          HI_write = 1'b0;    
          LO_write = 1'b0;    
          FlagRegWrite = 1'b0;
          IRWrite = 1'b0;     
          RegWrite = 1'b0;    
          MemWrite = 1'b0;
          ShiftOP = 0;     
          Seletor = 3'b010;     //
          mult_start = 1'b0; 
          div_start = 1'b0;  
          load_size = 2'b0;
          store_size = 1'b0;

          seletor_ulaA = 1'b0;  //
          seletor_ulaB = 2'b01; //
          RegDst = 4'b0;   
          MemtoReg = 4'b0; 
          SrInputSrc = 1'b0;
          SrNSrc = 3'b0;
          SrctoMem = 0;
          IorD = 3'b011; 
          PCSource = 2'b0;      //
          conSrc = 0;   
          HiLoSrc = 1'b0;

          reset_out = 1'b0;
        end

        ST_rte: begin
          STATE = ST_fetch;

          PC_write = 1'b1;      //
          A_write = 1'b0;     
          B_write = 1'b0;     
          EPC_write = 1'b0;   
          HI_write = 1'b0;    
          LO_write = 1'b0;    
          FlagRegWrite = 1'b0;
          IRWrite = 1'b0;     
          RegWrite = 1'b0;    
          MemWrite = 1'b0;
          ShiftOP = 0;     
          Seletor = 3'b000;
          mult_start = 1'b0; 
          div_start = 1'b0;  
          load_size = 2'b0;
          store_size = 1'b0;

          seletor_ulaA = 1'b0;
          seletor_ulaB = 2'b0;
          RegDst = 4'b0;   
          MemtoReg = 4'b0; 
          SrInputSrc = 1'b0;
          SrNSrc = 3'b0;
          SrctoMem = 0;
          IorD = 3'b011; 
          PCSource = 2'b11;      //
          conSrc = 0;   
          HiLoSrc = 1'b0;

          reset_out = 1'b0;
        end

        ST_xchg: begin
          if (COUNTER == 1'b0)begin
            PC_write = 1'b0;   
            A_write = 1'b0;     
            B_write = 1'b0;     
            EPC_write = 1'b0;   
            HI_write = 1'b0;    
            LO_write = 1'b0;    
            FlagRegWrite = 1'b0;
            IRWrite = 1'b0;     
            RegWrite = 1'b1;  //*  
            MemWrite = 1'b0;   
            ShiftOP = 0;     
            Seletor = 3'b0;     
            mult_start = 1'b0; 
            div_start = 1'b0;  
            load_size = 2'b0;
            store_size = 1'b0;

            seletor_ulaA = 1'b0;
            seletor_ulaB = 2'b0;
            RegDst = 3'b000; //*
            MemtoReg = 4'b1001; //*
            SrInputSrc = 1'b0;
            SrNSrc = 3'b0;
            SrctoMem = 0;
            IorD = 3'b000; 
            PCSource = 2'b00;
            conSrc = 0;   
            HiLoSrc = 1'b0;

            reset_out = 1'b0;
            COUNTER = COUNTER + 1;
            STATE = ST_xchg; 
          end else if (COUNTER == 1'b1) begin
            STATE = ST_fetch;
            RegDst = 3'b100; //*
            MemtoReg = 4'b0111; //*
            RegWrite = 1'b1;  //*
            COUNTER = 0;
          end
        end

        ST_addi: begin
          STATE = ST_fetch;
          PC_write = 1'b0;  
          A_write = 1'b0;     
          B_write = 1'b0;     
          EPC_write = 1'b0;   
          HI_write = 1'b0;    
          LO_write = 1'b0;    
          FlagRegWrite = 1'b0;
          IRWrite = 1'b0;     
          RegWrite = 1'b1;  //*  
          MemWrite = 1'b0;   
          ShiftOP = 0;     
          Seletor = 3'b001; //*     
          mult_start = 1'b0; 
          div_start = 1'b0;  
          load_size = 2'b0;
          store_size = 1'b0;

          seletor_ulaA = 1'b1; //*
          seletor_ulaB = 2'b10; //*
          RegDst = 3'b000; //*
          MemtoReg = 4'b0000; //* 
          SrInputSrc = 1'b0;
          SrNSrc = 3'b0;
          SrctoMem = 0;
          IorD = 3'b000; 
          PCSource = 2'b00;
          conSrc = 0;   
          HiLoSrc = 1'b0;

          reset_out = 1'b0; 

          CAN_OVERFLOW = 1'b1;

        end

        ST_addiu: begin
          PC_write = 1'b0;    
          A_write = 1'b0;     
          B_write = 1'b0;     
          EPC_write = 1'b0;   
          HI_write = 1'b0;    
          LO_write = 1'b0;    
          FlagRegWrite = 1'b0;
          IRWrite = 1'b0;     
          RegWrite = 1'b1; //*
          MemWrite = 1'b0;   
          ShiftOP = 0;     
          Seletor = 3'b001; //*   
          mult_start = 1'b0; 
          div_start = 1'b0;  
          load_size = 2'b0;
          store_size = 1'b0;

          seletor_ulaA = 1'b1; //*
          seletor_ulaB = 2'b10;//*
          RegDst = 3'b000; //*
          MemtoReg = 4'b0; //*
          SrInputSrc = 1'b0;
          SrNSrc = 3'b0;
          SrctoMem = 0;
          IorD = 3'b000; 
          PCSource = 2'b00;
          conSrc = 0;   
          HiLoSrc = 1'b0;

          reset_out = 1'b0; 
          STATE = ST_fetch;
        end

        ST_beq: begin
          PC_write = 1'b0; //*    
          writeCondition = 1;
          A_write = 1'b0;     
          B_write = 1'b0;     
          EPC_write = 1'b0;   
          HI_write = 1'b0;    
          LO_write = 1'b0;    
          FlagRegWrite = 1'b0; //*
          IRWrite = 1'b0;     
          RegWrite = 1'b0; 
          MemWrite = 1'b0;   
          ShiftOP = 0;     
          Seletor = 3'b001; //*
          mult_start = 1'b0; 
          div_start = 1'b0;  
          load_size = 2'b0;
          store_size = 1'b0;

          seletor_ulaA = 1'b0; //*
          seletor_ulaB = 2'b11; //* 
          RegDst = 3'b000;
          MemtoReg = 4'b0;
          SrInputSrc = 1'b0;
          SrNSrc = 3'b0;
          SrctoMem = 0;
          IorD = 3'b000; 
          PCSource = 2'b00; //*
          conSrc = 2'b00; //*   
          HiLoSrc = 1'b0;

          reset_out = 1'b0; 
          STATE = ST_fetch;        
        end

        ST_bne: begin
          PC_write = 0; //*    
          writeCondition = 1;
          A_write = 1'b0;     
          B_write = 1'b0;     
          EPC_write = 1'b0;   
          HI_write = 1'b0;    
          LO_write = 1'b0;    
          FlagRegWrite = 1'b0; //*
          IRWrite = 1'b0;     
          RegWrite = 1'b0; 
          MemWrite = 1'b0;   
          ShiftOP = 0;     
          Seletor = 3'b001; //*
          mult_start = 1'b0; 
          div_start = 1'b0;  
          load_size = 2'b0;
          store_size = 1'b0;

          seletor_ulaA = 1'b0; //*
          seletor_ulaB = 2'b11; //* 
          RegDst = 3'b000;
          MemtoReg = 4'b0;
          SrInputSrc = 1'b0;
          SrNSrc = 3'b0;
          SrctoMem = 0;
          IorD = 3'b000; 
          PCSource = 2'b00; //*
          conSrc = 2'b01; //*   
          HiLoSrc = 1'b0;

          reset_out = 1'b0; 
          STATE = ST_fetch;
        end

        ST_ble: begin
          PC_write = 0; //*    
          writeCondition = 1;
          A_write = 1'b0;     
          B_write = 1'b0;     
          EPC_write = 1'b0;   
          HI_write = 1'b0;    
          LO_write = 1'b0;    
          FlagRegWrite = 1'b0; //*
          IRWrite = 1'b0;     
          RegWrite = 1'b0; 
          MemWrite = 1'b0;   
          ShiftOP = 0;     
          Seletor = 3'b001; //*
          mult_start = 1'b0; 
          div_start = 1'b0;  
          load_size = 2'b0;
          store_size = 1'b0;

          seletor_ulaA = 1'b0; //*
          seletor_ulaB = 2'b11; //* 
          RegDst = 3'b000;
          MemtoReg = 4'b0;
          SrInputSrc = 1'b0;
          SrNSrc = 3'b0;
          SrctoMem = 0;
          IorD = 3'b000; 
          PCSource = 2'b00; //*
          conSrc = 2'b10; //*   
          HiLoSrc = 1'b0;

          reset_out = 1'b0; 
          STATE = ST_fetch;
        
        end

        ST_bgt:begin
          PC_write = 0; //*    
          writeCondition = 1;
          A_write = 1'b0;     
          B_write = 1'b0;     
          EPC_write = 1'b0;   
          HI_write = 1'b0;    
          LO_write = 1'b0;    
          FlagRegWrite = 1'b0; //*
          IRWrite = 1'b0;     
          RegWrite = 1'b0; 
          MemWrite = 1'b0;   
          ShiftOP = 0;     
          Seletor = 3'b001; //*
          mult_start = 1'b0; 
          div_start = 1'b0;  
          load_size = 2'b0;
          store_size = 1'b0;

          seletor_ulaA = 1'b0; //*
          seletor_ulaB = 2'b11; //* 
          RegDst = 3'b000;
          MemtoReg = 4'b0;
          SrInputSrc = 1'b0;
          SrNSrc = 3'b0;
          SrctoMem = 0;
          IorD = 3'b000; 
          PCSource = 2'b00; //*
          conSrc = 2'b11; //*   
          HiLoSrc = 1'b0;

          reset_out = 1'b0; 
          STATE = ST_fetch;    
        end

        ST_sram: begin
          if (COUNTER <= 1'b1)begin
            PC_write = 1'b0;   
            A_write = 1'b0;     
            B_write = 1'b0;     
            EPC_write = 1'b0;   
            HI_write = 1'b0;    
            LO_write = 1'b0;    
            FlagRegWrite = 1'b0;
            IRWrite = 1'b0;     
            RegWrite = 1'b0;  
            MemWrite = 1'b0;
            ShiftOP = 0;     
            Seletor = 3'b001; //*     
            mult_start = 1'b0; 
            div_start = 1'b0;  
            load_size = 2'b0;
            store_size = 1'b0;

            seletor_ulaA = 1'b1; //*
            seletor_ulaB = 2'b10; //*
            RegDst = 3'b000;
            MemtoReg = 4'b0000;
            SrInputSrc = 1'b0;
            SrNSrc = 3'b0;
            SrctoMem = 0;
            IorD = 3'b100; //* 
            PCSource = 2'b00;
            conSrc = 0;   
            HiLoSrc = 1'b0;

            reset_out = 1'b0;
            COUNTER = COUNTER + 1;
            STATE = ST_sram; 
          end else if (COUNTER == 2'b10) begin
            STATE = ST_sram;
            SrNSrc = 3'b001; //*
            SrInputSrc = 1'b0; //*
            ShiftOP = 3'b001; //*
            COUNTER = COUNTER + 1;
          end else if (COUNTER == 2'b11) begin
            STATE = ST_sram;
            ShiftOP = 3'b100; //*
            COUNTER = COUNTER + 1;
          end else if (COUNTER == 3'b100) begin
            STATE = ST_fetch;
            MemtoReg = 3'b110; //*
            RegDst = 1'b0; //*
            RegWrite = 1'b1; //*
            COUNTER = 0;
          end
        end

        ST_lb: begin
          if (COUNTER <= 1'b1)begin
            PC_write = 1'b0;   
            A_write = 1'b0;     
            B_write = 1'b0;     
            EPC_write = 1'b0;   
            HI_write = 1'b0;    
            LO_write = 1'b0;    
            FlagRegWrite = 1'b0;
            IRWrite = 1'b0;     
            RegWrite = 1'b0;  
            MemWrite = 1'b0; //*  
            ShiftOP = 0;     
            Seletor = 3'b001; //*     
            mult_start = 1'b0; 
            div_start = 1'b0;  
            load_size = 2'b0;
            store_size = 1'b0;

            seletor_ulaA = 1'b1; //*
            seletor_ulaB = 2'b10; //*
            RegDst = 3'b000;
            MemtoReg = 4'b0000;
            SrInputSrc = 1'b0;
            SrNSrc = 3'b0;
            SrctoMem = 0;
            IorD = 3'b100; //* 
            PCSource = 2'b00;
            conSrc = 0;   
            HiLoSrc = 1'b0;

            reset_out = 1'b0;
            COUNTER = COUNTER + 1;
            STATE = ST_lb; 
          end else if (COUNTER == 2'b10) begin
            STATE = ST_fetch;
            RegWrite = 1'b1;  //*
            MemtoReg = 4'b0101; //*
            load_size = 2'b00; //*
            RegDst = 1'b0; //*
            COUNTER = 0;
          end
        end

        ST_lh: begin
          if (COUNTER <= 1'b1)begin
            PC_write = 1'b0;   
            A_write = 1'b0;     
            B_write = 1'b0;     
            EPC_write = 1'b0;   
            HI_write = 1'b0;    
            LO_write = 1'b0;    
            FlagRegWrite = 1'b0;
            IRWrite = 1'b0;     
            RegWrite = 1'b0;  
            MemWrite = 1'b0; //*  
            ShiftOP = 0;     
            Seletor = 3'b001; //*     
            mult_start = 1'b0; 
            div_start = 1'b0;  
            load_size = 2'b0;
            store_size = 1'b0;

            seletor_ulaA = 1'b1; //*
            seletor_ulaB = 2'b10; //*
            RegDst = 3'b000;
            MemtoReg = 4'b0000;
            SrInputSrc = 1'b0;
            SrNSrc = 3'b0;
            SrctoMem = 0;
            IorD = 3'b100; //* 
            PCSource = 2'b00;
            conSrc = 0;   
            HiLoSrc = 1'b0;

            reset_out = 1'b0;
            COUNTER = COUNTER + 1;
            STATE = ST_lh; 
          end else if (COUNTER == 2'b10) begin
            STATE = ST_fetch;
            RegWrite = 1'b1;  //*
            MemtoReg = 4'b0101; //*
            load_size = 2'b01; //*
            RegDst = 1'b0; //*
            COUNTER = 0;
          end
        end

        ST_lui: begin
          PC_write = 1'b0;   
          A_write = 1'b0;     
          B_write = 1'b0;     
          EPC_write = 1'b0;   
          HI_write = 1'b0;    
          LO_write = 1'b0;    
          FlagRegWrite = 1'b0;
          IRWrite = 1'b0;     
          RegWrite = 1'b1;    //*
          MemWrite = 1'b0;   
          ShiftOP = 0;     
          Seletor = 3'b0;     
          mult_start = 1'b0; 
          div_start = 1'b0;  
          load_size = 2'b0;
          store_size = 1'b0;

          seletor_ulaA = 1'b0;
          seletor_ulaB = 2'b0;
          RegDst = 3'b000; 
          MemtoReg = 4'b1000; //*
          SrInputSrc = 1'b0;
          SrNSrc = 3'b0;
          SrctoMem = 0;
          IorD = 3'b000; 
          PCSource = 2'b00; 
          conSrc = 0;   
          HiLoSrc = 1'b0;

          reset_out = 1'b0; 
          STATE = ST_fetch;
        end

        ST_lw: begin
          if (COUNTER <= 1'b1)begin
            PC_write = 1'b0;   
            A_write = 1'b0;     
            B_write = 1'b0;     
            EPC_write = 1'b0;   
            HI_write = 1'b0;    
            LO_write = 1'b0;    
            FlagRegWrite = 1'b0;
            IRWrite = 1'b0;     
            RegWrite = 1'b0;  
            MemWrite = 1'b0; //*  
            ShiftOP = 0;     
            Seletor = 3'b001; //*     
            mult_start = 1'b0; 
            div_start = 1'b0;  
            load_size = 2'b0;
            store_size = 1'b0;

            seletor_ulaA = 1'b1; //*
            seletor_ulaB = 2'b10; //*
            RegDst = 3'b000;
            MemtoReg = 4'b0000;
            SrInputSrc = 1'b0;
            SrNSrc = 3'b0;
            SrctoMem = 0;
            IorD = 3'b100; //* 
            PCSource = 2'b00;
            conSrc = 0;   
            HiLoSrc = 1'b0;

            reset_out = 1'b0;
            COUNTER = COUNTER + 1;
            STATE = ST_lw; 
          end else if (COUNTER == 2'b10) begin
            STATE = ST_fetch;
            RegWrite = 1'b1;  //*
            MemtoReg = 4'b0001; //*
            RegDst = 1'b0; //*
            COUNTER = 0;
          end
        end

        ST_sb: begin
          if (COUNTER <= 1'b1)begin
            PC_write = 1'b0;   
            A_write = 1'b0;     
            B_write = 1'b0;     
            EPC_write = 1'b0;   
            HI_write = 1'b0;    
            LO_write = 1'b0;    
            FlagRegWrite = 1'b0;
            IRWrite = 1'b0;     
            RegWrite = 1'b0;  
            MemWrite = 1'b0; //*  
            ShiftOP = 0;     
            Seletor = 3'b001; //*     
            mult_start = 1'b0; 
            div_start = 1'b0;  
            load_size = 2'b0;
            store_size = 1'b0;

            seletor_ulaA = 1'b1; //*
            seletor_ulaB = 2'b10; //*
            RegDst = 3'b000;
            MemtoReg = 4'b0000;
            SrInputSrc = 1'b0;
            SrNSrc = 3'b0;
            SrctoMem = 0;
            IorD = 3'b100; //* 
            PCSource = 2'b00;
            conSrc = 0;   
            HiLoSrc = 1'b0;

            reset_out = 1'b0;
            COUNTER = COUNTER + 1;
            STATE = ST_sb; 
          end else if (COUNTER == 2'b10) begin
            STATE = ST_fetch;
            load_size = 2'b11; //*
            store_size = 1'b0; //*
            SrctoMem = 1'b1; //*
            MemWrite = 1'b1; //*
            COUNTER = 0;
          end
        end

        ST_sh: begin
          if (COUNTER <= 1'b1)begin
            PC_write = 1'b0;   
            A_write = 1'b0;     
            B_write = 1'b0;     
            EPC_write = 1'b0;   
            HI_write = 1'b0;    
            LO_write = 1'b0;    
            FlagRegWrite = 1'b0;
            IRWrite = 1'b0;     
            RegWrite = 1'b0;  
            MemWrite = 1'b0; //*  
            ShiftOP = 0;     
            Seletor = 3'b001; //*     
            mult_start = 1'b0; 
            div_start = 1'b0;  
            load_size = 2'b0;
            store_size = 1'b0;

            seletor_ulaA = 1'b1; //*
            seletor_ulaB = 2'b10; //*
            RegDst = 3'b000;
            MemtoReg = 4'b0000;
            SrInputSrc = 1'b0;
            SrNSrc = 3'b0;
            SrctoMem = 0;
            IorD = 3'b100; //* 
            PCSource = 2'b00;
            conSrc = 0;   
            HiLoSrc = 1'b0;

            reset_out = 1'b0;
            COUNTER = COUNTER + 1;
            STATE = ST_sh; 
          end else if (COUNTER == 2'b10) begin
            STATE = ST_fetch;
            load_size = 2'b10; //*
            store_size = 1'b1; //*
            SrctoMem = 1'b1; //*
            MemWrite = 1'b1; //*
            COUNTER = 0;
          end
        end

        ST_slti: begin
          PC_write = 1'b0;    
          A_write = 1'b0;     
          B_write = 1'b0;     
          EPC_write = 1'b0;   
          HI_write = 1'b0;    
          LO_write = 1'b0;    
          FlagRegWrite = 1'b0;
          IRWrite = 1'b0;     
          RegWrite = 1'b1;//*
          MemWrite = 1'b0;   
          ShiftOP = 0;     
          Seletor = 3'b111; //*
          mult_start = 1'b0; 
          div_start = 1'b0;  
          load_size = 2'b0;
          store_size = 1'b0;

          seletor_ulaA = 1'b1; //*
          seletor_ulaB = 2'b10; //* 
          RegDst = 3'b000; //*
          MemtoReg = 4'b1010; //*
          SrInputSrc = 1'b0;
          SrNSrc = 3'b0;
          SrctoMem = 0;
          IorD = 3'b000; 
          PCSource = 2'b00;
          conSrc = 0;   
          HiLoSrc = 1'b0;

          reset_out = 1'b0; 
          STATE = ST_fetch;
        end

        ST_sw: begin
          STATE = ST_fetch;

          PC_write = 1'b0;
          A_write = 1'b0;     
          B_write = 1'b0;     
          EPC_write = 1'b0;   
          HI_write = 1'b0;    
          LO_write = 1'b0;    
          FlagRegWrite = 1'b0;
          IRWrite = 1'b0;     
          RegWrite = 1'b0;    
          MemWrite = 1'b1;        //
          ShiftOP = 0;     
          Seletor = 3'b001;       //
          mult_start = 1'b0; 
          div_start = 1'b0;  
          load_size = 2'b0;
          store_size = 1'b0;

          seletor_ulaA = 1'b1;   //
          seletor_ulaB = 2'b10;   //
          RegDst = 4'b0;   
          MemtoReg = 4'b0; 
          SrInputSrc = 1'b0;
          SrNSrc = 3'b0;
          SrctoMem = 0;         //
          IorD = 3'b100;        //
          PCSource = 2'b00;
          conSrc = 0;
          HiLoSrc = 1'b0;

          reset_out = 1'b0;
        end

        ST_j: begin 
          PC_write = 1'b1;  //* 
          A_write = 1'b0;     
          B_write = 1'b0;     
          EPC_write = 1'b0;   
          HI_write = 1'b0;    
          LO_write = 1'b0;    
          FlagRegWrite = 1'b0;
          IRWrite = 1'b0;     
          RegWrite = 1'b0;  
          MemWrite = 1'b0;   
          ShiftOP = 0;     
          Seletor = 3'b0;     
          mult_start = 1'b0; 
          div_start = 1'b0;  
          load_size = 2'b0;
          store_size = 1'b0;

          seletor_ulaA = 1'b0;
          seletor_ulaB = 2'b0;
          RegDst = 3'b0;
          MemtoReg = 4'b0; 
          SrInputSrc = 1'b0;
          SrNSrc = 3'b0;
          SrctoMem = 0;
          IorD = 3'b000; 
          PCSource = 2'b01;  //*
          conSrc = 0;   
          HiLoSrc = 1'b0;

          reset_out = 1'b0; 
          STATE = ST_fetch;
        end

        ST_jal: begin
          PC_write = 1'b1; //*   
          A_write = 1'b0;     
          B_write = 1'b0;     
          EPC_write = 1'b0;   
          HI_write = 1'b0;    
          LO_write = 1'b0;    
          FlagRegWrite = 1'b0;
          IRWrite = 1'b0;     
          RegWrite = 1'b1;  //*  
          MemWrite = 1'b0;   
          ShiftOP = 0;     
          Seletor = 3'b0;     
          mult_start = 1'b0; 
          div_start = 1'b0;  
          load_size = 2'b0;
          store_size = 1'b0;

          seletor_ulaA = 1'b0;
          seletor_ulaB = 2'b0;
          RegDst = 3'b010; //*
          MemtoReg = 4'b0; 
          SrInputSrc = 1'b0;
          SrNSrc = 3'b0;
          SrctoMem = 0;
          IorD = 3'b000; 
          PCSource = 2'b01; //*
          conSrc = 0;   
          HiLoSrc = 1'b0;

          reset_out = 1'b0; 
          STATE = ST_fetch;
        end

        ST_conditional_branch: begin
          PC_write = 1'b0;    
          A_write = 1'b0;     
          B_write = 1'b0;     
          EPC_write = 1'b0;   
          HI_write = 1'b0;    
          LO_write = 1'b0;    
          FlagRegWrite = 1'b1; //*
          IRWrite = 1'b0;     
          RegWrite = 1'b0; 
          MemWrite = 1'b0;   
          ShiftOP = 0;     
          Seletor = 3'b111; //*
          mult_start = 1'b0; 
          div_start = 1'b0;  
          load_size = 2'b0;
          store_size = 1'b0;

          seletor_ulaA = 1'b1; //*
          seletor_ulaB = 2'b00; //*
          RegDst = 3'b000;
          MemtoReg = 4'b0;
          SrInputSrc = 1'b0;
          SrNSrc = 3'b0;
          SrctoMem = 0;
          IorD = 3'b000; 
          PCSource = 2'b00;
          conSrc = 0;   
          HiLoSrc = 1'b0;

          reset_out = 1'b0;

          case(OPCODE)

            opcode_beq: begin
              STATE = ST_beq;
            end
            opcode_bne: begin
              STATE = ST_bne;
            end
            opcode_ble: begin
              STATE = ST_ble;
            end
            opcode_bgt:begin
              STATE = ST_bgt;
            end

          endcase

        end

        ST_invalid_opcode: begin
          if (COUNTER < 6'b000010) begin
            STATE = ST_invalid_opcode; //*

            PC_write = 1'b0;    
            A_write = 1'b0;     
            B_write = 1'b0;     
            EPC_write = 1'b1;     //
            HI_write = 1'b0;    
            LO_write = 1'b0;    
            FlagRegWrite = 1'b0;
            IRWrite = 1'b0;     
            RegWrite = 1'b0;    
            MemWrite = 1'b0;      //
            ShiftOP = 0;     
            Seletor = 3'b010;     //
            mult_start = 1'b0; 
            div_start = 1'b0;  
            load_size = 2'b0;
            store_size = 1'b0;

            seletor_ulaA = 1'b0;  //
            seletor_ulaB = 2'b01; //
            RegDst = 4'b0;   
            MemtoReg = 4'b0; 
            SrInputSrc = 1'b0;
            SrNSrc = 3'b0;
            SrctoMem = 0;
            IorD = 3'b000;        //
            PCSource = 2'b0; 
            conSrc = 0;   
            HiLoSrc = 1'b0;

            reset_out = 1'b0;

            COUNTER = COUNTER + 1;
          end else begin
            STATE = ST_fetch; //*

            PC_write = 1'b1;      //
            A_write = 1'b0;     
            B_write = 1'b0;     
            EPC_write = 1'b1;
            HI_write = 1'b0;    
            LO_write = 1'b0;    
            FlagRegWrite = 1'b0;
            IRWrite = 1'b0;     
            RegWrite = 1'b0;    
            MemWrite = 1'b0;
            ShiftOP = 0;     
            Seletor = 3'b000;
            mult_start = 1'b0; 
            div_start = 1'b0;  
            load_size = 2'b0;     //
            store_size = 1'b0;

            seletor_ulaA = 1'b0;
            seletor_ulaB = 2'b01;
            RegDst = 4'b0;   
            MemtoReg = 4'b0; 
            SrInputSrc = 1'b0;
            SrNSrc = 3'b0;
            SrctoMem = 0;
            IorD = 3'b000;
            PCSource = 2'b10;     //
            conSrc = 0;   
            HiLoSrc = 1'b0;

            reset_out = 1'b0;

            COUNTER = 0;
          end
        end

        ST_overflow: begin
          if (COUNTER < 6'b000010) begin
            STATE = ST_overflow; //*

            PC_write = 1'b0;    
            A_write = 1'b0;     
            B_write = 1'b0;     
            EPC_write = 1'b1;     //
            HI_write = 1'b0;    
            LO_write = 1'b0;    
            FlagRegWrite = 1'b0;
            IRWrite = 1'b0;     
            RegWrite = 1'b0;    
            MemWrite = 1'b0;      //
            ShiftOP = 0;     
            Seletor = 3'b010;     //
            mult_start = 1'b0; 
            div_start = 1'b0;  
            load_size = 2'b0;
            store_size = 1'b0;

            seletor_ulaA = 1'b0;  //
            seletor_ulaB = 2'b01; //
            RegDst = 4'b0;   
            MemtoReg = 4'b0; 
            SrInputSrc = 1'b0;
            SrNSrc = 3'b0;
            SrctoMem = 0;
            IorD = 3'b001;        //
            PCSource = 2'b0; 
            conSrc = 0;   
            HiLoSrc = 1'b0;

            reset_out = 1'b0;

            COUNTER = COUNTER + 1;
          end else begin
            STATE = ST_fetch; //*

            PC_write = 1'b1;      //
            A_write = 1'b0;     
            B_write = 1'b0;     
            EPC_write = 1'b1;
            HI_write = 1'b0;    
            LO_write = 1'b0;    
            FlagRegWrite = 1'b0;
            IRWrite = 1'b0;     
            RegWrite = 1'b0;    
            MemWrite = 1'b0;
            ShiftOP = 0;     
            Seletor = 3'b000;
            mult_start = 1'b0; 
            div_start = 1'b0;  
            load_size = 2'b0;     //
            store_size = 1'b0;

            seletor_ulaA = 1'b0;
            seletor_ulaB = 2'b01;
            RegDst = 4'b0;   
            MemtoReg = 4'b0; 
            SrInputSrc = 1'b0;
            SrNSrc = 3'b0;
            SrctoMem = 0;
            IorD = 3'b000;
            PCSource = 2'b10;     //
            conSrc = 0;   
            HiLoSrc = 1'b0;

            reset_out = 1'b0;

            COUNTER = 0;
          end
        end

        ST_divzero: begin
          if (COUNTER < 6'b000010) begin
            STATE = ST_divzero; //*

            PC_write = 1'b0;    
            A_write = 1'b0;     
            B_write = 1'b0;     
            EPC_write = 1'b1;     //
            HI_write = 1'b0;    
            LO_write = 1'b0;    
            FlagRegWrite = 1'b0;
            IRWrite = 1'b0;     
            RegWrite = 1'b0;    
            MemWrite = 1'b0;      //
            ShiftOP = 0;     
            Seletor = 3'b010;     //
            mult_start = 1'b0; 
            div_start = 1'b0;  
            load_size = 2'b0;
            store_size = 1'b0;

            seletor_ulaA = 1'b0;  //
            seletor_ulaB = 2'b01; //
            RegDst = 4'b0;   
            MemtoReg = 4'b0; 
            SrInputSrc = 1'b0;
            SrNSrc = 3'b0;
            SrctoMem = 0;
            IorD = 3'b010;        //
            PCSource = 2'b0; 
            conSrc = 0;   
            HiLoSrc = 1'b0;

            reset_out = 1'b0;

            COUNTER = COUNTER + 1;
          end else begin
            STATE = ST_fetch; //*

            PC_write = 1'b1;      //
            A_write = 1'b0;     
            B_write = 1'b0;     
            EPC_write = 1'b0;
            HI_write = 1'b0;    
            LO_write = 1'b0;    
            FlagRegWrite = 1'b0;
            IRWrite = 1'b0;     
            RegWrite = 1'b0;    
            MemWrite = 1'b0;
            ShiftOP = 0;     
            Seletor = 3'b000;
            mult_start = 1'b0; 
            div_start = 1'b0;  
            load_size = 2'b0;     //
            store_size = 1'b0;

            seletor_ulaA = 1'b0;
            seletor_ulaB = 2'b01;
            RegDst = 4'b0;   
            MemtoReg = 4'b0; 
            SrInputSrc = 1'b0;
            SrNSrc = 3'b0;
            SrctoMem = 0;
            IorD = 3'b000;
            PCSource = 2'b10;     //
            conSrc = 0;   
            HiLoSrc = 1'b0;

            reset_out = 1'b0;

            COUNTER = 0;
          end
        end

      endcase

    end

  end

endmodule