module div(
    input wire [31:0] b,
    input wire [31:0] q,
    input wire clk,
    input wire start,
    input wire reset,
    output reg divzero,
    output reg [31:0] hi,
    output reg [31:0] lo
);
    reg [31:0] a;
    reg [31:0] divisor;
    reg [31:0] dividendo;
    reg [5:0] contador;
    reg status = 1'b0;

    reg sinalDivisor;
    reg sinalDividendo;

    always @(posedge clk) begin
        if (start == 1'b1) begin
                a = 32'b0;
                dividendo = q;
                divisor = b;
                contador = 6'd32;
                hi = 32'b0;
                lo = 32'b0;
                status = 1'b1;
                divzero = 1'b0;
                sinalDivisor = divisor[31];   
                sinalDividendo = dividendo[31]; 
                if (divisor[31] == 1'b1) begin
                  divisor = ~(divisor) + 1'b1;
                end

                if (dividendo[31] == 1'b1) begin
                  dividendo = ~(dividendo) + 1'b1;
                end

        end
        if (reset == 1'b1 && status == 1'b1)begin
                    a = 32'b0;
                    dividendo = q;
                    divisor = b;
                    contador = 6'd32;
                    hi = 32'b0;
                    lo = 32'b0;
                    divzero = 1'b0;
                    sinalDivisor = divisor[31];   
                    sinalDividendo = dividendo[31]; 
        end

        else if (contador != 0 && status == 1'b1) begin

            if(divisor == 32'b0) begin

                divzero = 1'b1;
                contador = 6'b0;
            end

            else begin
            {a,dividendo} = {a, dividendo} << 1'b1;
            a = a - divisor;
            if (a[31] == 1'b1)begin
                a = a + divisor;
            end
            else begin
                dividendo[0] = 1'b1;
            end
            contador = contador - 1'b1;
            end
        end
        if (contador == 6'b0 && divzero == 1'b0 && status == 1'b1) begin

          if (sinalDividendo == 1'b1) begin
            dividendo = ~dividendo + 1'b1;
          end

          if (sinalDivisor == 1'b1) begin
            dividendo = ~dividendo + 1'b1;
          end
                hi = a;
                lo = dividendo;
                status = 1'b0;
        end
    end
endmodule
