// RVFI wrapper for the single-cycle rv32i core.

//
// Rewritten to match the pattern used by NERV and PicoRV32's real
// wrapper.sv files: the DUT itself generates all rvfi_* signals as
// genuine output ports, and this wrapper just passes them straight
// through via the RVFI_CONN macro. No hierarchical dot-path
// references into the DUT's internals -- those broke under
// SymbiYosys's `prep -flatten` pass (surfaced as "used but has no
// driver" warnings on wires like wrapper.dut.rs1Data).
//
// `RVFI_OUTPUTS and `RVFI_CONN come from checks/rvfi_macros.vh,
// included automatically by genchecks.py's generated defines.sv.
module rvfi_wrapper (
  input clock,
  input reset,
  `RVFI_OUTPUTS

);

  rv32i_formal dut (
    .clk(clock),
    .reset(reset),
    .currAddress(),   // unused by RVFI, left unconnected
    `RVFI_CONN
  );

endmodule

