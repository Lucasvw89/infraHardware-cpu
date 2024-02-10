module mult(
    input wire [31:0] q,
    input wire [31:0] m,
    input wire clk,
    input wire start,
    input wire reset,
    output reg [31:0] hi,
    output reg [31:0] lo
);
    reg [31:0] a;
    reg regqcomparativo;
    reg [31:0] multiplicando;
    reg [31:0] multiplicador;
    reg [5:0] contador;
    reg status = 1'b0;
    
        always @ (posedge clk)
            begin
                if (start == 1'b1) begin
                a = 32'b0;
                regqcomparativo = 1'b0;
                multiplicando = q;
                multiplicador = m;
                contador = 6'd32;
                hi = 32'b0;
                lo = 32'b0;
                status = 1'b1;
                end
                if (reset == 1'b1 && status == 1'b1)begin
                    a = 32'b0;
                    regqcomparativo = 1'b0;
                    multiplicando = q;
                    multiplicador = m;
                    contador = 6'd32;
                    hi = 32'b0;
                    lo = 32'b0;
                end
                else if (contador != 0 && status == 1'b1) begin

                if (multiplicando[0] == 1'b1 && regqcomparativo == 1'b0) // se true a = a - m
                begin
                    a = a - multiplicador;
                end
                else if (multiplicando[0] == 1'b0 && regqcomparativo == 1'b1) //// a =  a+m
                begin
                    a = a+multiplicador;
                end
                {a, multiplicando, regqcomparativo} = {a, multiplicando, regqcomparativo} >> 1'b1;

                if(a[30] == 1'b1)begin

                    a[31] = 1'b1;

                end
                
                contador = contador - 1'b1;
            if (contador == 6'b0) begin
                hi = a;
                lo = multiplicando;
                status = 1'b0;
            end
        end
    end
endmodule

