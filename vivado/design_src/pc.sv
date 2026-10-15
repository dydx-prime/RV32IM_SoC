//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/12/2026 09:46:42 PM
// Design Name: 
// Module Name: pc
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


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
