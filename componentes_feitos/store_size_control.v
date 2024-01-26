module store_size_control(
  input wire store_size, // fio azul
  input wire [31:0] store_input, // vem de B
  input wire [23:0] byte_junction_input, // vem do load_size_control
  output wire [31:0] out // vai pra memoria
);

  assign out = (store_size == 0) ? {{byte_junction_input}, {store_input[7:0]}} :
               {{byte_junction_input[15:0]}, store_input[15:0]};

endmodule
