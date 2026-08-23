// instruction memory
module imem #(parameter FILE = "prog.dat")(
  input [31:0] pc,
  output logic [31:0] instruction
);

  logic [31:0] memory [0:2047];
  
  initial begin
    $readmemh(FILE, memory);
  end

  assign instruction = memory[pc[31:2]];

endmodule
