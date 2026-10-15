
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/12/2026 09:38:28 PM
// Design Name: 
// Module Name: pc4
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


module pc4(
  input [31:0] pc,
  output logic [31:0] pcPlus4
);

  assign pcPlus4 = pc + 32'd4;

endmodule
