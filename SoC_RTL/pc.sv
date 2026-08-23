module pc(
  input clk,
  input reset,
  input [31:0] nextPC,
  output logic [31:0] pc
);

  always_ff @(posedge clk)begin
    if(reset)
      pc <= 32'b0;
    else
      pc <= nextPC;
  end

endmodule
