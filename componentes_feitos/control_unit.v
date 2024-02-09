module control_unit (
  wire input clk,
  wire input reset
);

  cpu CPU_(
    clk,
    reset,
  );

endmodule
