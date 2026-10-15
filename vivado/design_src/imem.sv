//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/12/2026 09:46:42 PM
// Design Name: 
// Module Name: imem
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


// instruction memory
module imem #(parameter FILE = "instr.mem")(
  input [31:0] pc,
  output logic [31:0] instruction
);

  logic [31:0] memory [0:127];
  
  initial begin
    $readmemh(FILE, memory);
  end

  assign instruction = memory[pc[31:2]];

endmodule

