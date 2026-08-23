module pc4(
  input [31:0] pc,
  output logic [31:0] pcPlus4
);

  assign pcPlus4 = pc + 32'd4;

endmodule
