// SoC lol
module SoC(
  input clk,
  input reset,
  input RXD,
  output TXD,
  output [31:0] pc_sig
);

  wire uart_valid, uart_ready;
  wire [7:0] uart_wdata;

  corescore_emitter_uart #(.clk_freq_hz(50_000_000), .baud_rate(115200)) uart(
    .i_clk(clk),
    .i_rst(reset),
    .i_data(uart_wdata),
    .i_valid(uart_valid),

    .o_ready(uart_ready),
    .o_uart_tx(TXD)
  );

  rv32i core(
    .clk(clk),
    .reset(reset),
    .uart_ready(uart_ready),

    .currAddress(pc_sig),
    .uart_valid(uart_valid),
    .uart_wdata(uart_wdata)
  );

endmodule
