// Verilator testbench for SoC: drives clk/reset, samples TXD, decodes the
// UART bitstream (8N1, no parity) back into bytes, and either checks it
// against an expected string (hello-world style tests) or just dumps
// everything received to a file (large/variable output like the
// Mandelbrot PGM renderer).
//
// Usage:
//   ./Vsoc_sim                      -> hello-world mode, checks EXPECTED,
//                                       prints PASS/FAIL, exits 0/1
//   ./Vsoc_sim --dump out.pgm N     -> dump mode: run for up to N cycles,
//                                       write every received byte to
//                                       out.pgm, no pass/fail check
//
// Build/run via sim/run.sh (see comments there for manual invocation).

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <algorithm>
#include <string>
#include <vector>

#include "VSoC.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

// ---- Timing parameters: MUST match corescore_emitter_uart's instantiation
// in SoC.sv (clk_freq_hz / baud_rate) and the clock period driven below. ----

static constexpr double CLK_FREQ_HZ = 50e6;
static constexpr double BAUD_RATE   = 115200.0;
static constexpr double CLK_PERIOD_NS = 1e9 / CLK_FREQ_HZ;      // 20 ns @ 50 MHz
static constexpr double BIT_PERIOD_NS = 1e9 / BAUD_RATE;         // ~8680.6 ns/bit
static constexpr uint64_t CYCLES_PER_BIT =
    (uint64_t)(BIT_PERIOD_NS / CLK_PERIOD_NS + 0.5);              // ~434 cycles/bit

// Default simulation bound for hello-world mode. Dump mode takes its own
// cycle count from the command line since program runtime varies wildly.
static constexpr uint64_t DEFAULT_MAX_CYCLES = 500000;

static const std::string EXPECTED = "hello from rv32i\r\n";

// ---- CPI instrumentation ----
// This core is single-cycle (no visible pipeline registers, no stall
// logic): pc updates unconditionally every clock edge, so "instruction
// retired" == "pc changed" == "one clock cycle elapsed". CPI should

// therefore measure out to exactly 1.0; any deviation signals a bug
// (e.g. an instruction re-executing, an unintended stall) rather than
// something to "optimize" -- there's no pipeline here to hide latency in.
#include <map>


struct CpiCounter {
  bool has_prev_pc = false;
  uint32_t prev_pc = 0;
  uint64_t instr_count = 0;


  // Tracks how many times each PC value was seen on two back-to-back
  // cycles (pc[N] == pc[N-1]). The expected final halt loop (`j .`)
  // will show up here as one address with a huge count -- that's normal.
  // Anything ELSE showing up with count > 0, especially with count == 1
  // (a one-off repeat, not an infinite spin), is the real signal to chase.
  std::map<uint32_t, uint64_t> repeat_counts;
  uint64_t total_repeat_cycles = 0;
  uint64_t first_repeat_cycle = 0;
  bool seen_first_repeat = false;

  // ---- Halt-loop detection ----
  // A 1-cycle self-loop (pc == prev_pc for several cycles running) almost
  // certainly means the program has reached its terminal `j .`/`halt: j
  // halt` spin and is no longer doing real work. Once we see the same pc
  // repeat HALT_DETECT_THRESHOLD times in a row, we freeze instr_count/

  // cycle_count "as of last real progress" so CPI reflects only the
  // program's actual execution, not time spent parked at the end.
  static constexpr int HALT_DETECT_THRESHOLD = 3;
  int same_pc_streak = 0;
  bool halt_detected = false;
  uint64_t instr_count_at_halt = 0;
  uint64_t cycle_at_halt = 0;

  void sample(uint32_t pc, bool in_reset, uint64_t cycle_num) {
    if (in_reset) {
      has_prev_pc = false;  // don't count anything while held in reset
      return;
    }
    if (!has_prev_pc) {
      // First cycle out of reset: this is the first fetch, count it.
      has_prev_pc = true;
      prev_pc = pc;
      instr_count++;
      return;
    }
    if (pc != prev_pc) {
      instr_count++;
      prev_pc = pc;
      same_pc_streak = 0;
    } else {
      // pc held steady across a clock edge -- log it.
      repeat_counts[pc]++;
      total_repeat_cycles++;

      if (!seen_first_repeat) {

        seen_first_repeat = true;
        first_repeat_cycle = cycle_num;
      }
      same_pc_streak++;
      if (!halt_detected && same_pc_streak >= HALT_DETECT_THRESHOLD) {
        halt_detected = true;
        // instr_count/cycle_num as of just before this streak started is
        // the "real work" boundary -- back out the streak itself so we
        // don't include the detection window in either count.

        instr_count_at_halt = instr_count;
        cycle_at_halt = cycle_num - same_pc_streak;
      }
    }

    // NOTE: if the program deliberately branches back to the exact same
    // pc it was already on (a true 1-cycle self-loop, e.g. `j .`), this
    // undercounts by not seeing pc "change". That's a real edge case for
    // an infinite halt loop specifically -- harmless for CPI purposes
    // since you wouldn't count cycles spent spinning at the end anyway.
  }
};


// ---------------------------------------------------------------------

struct UartDecoder {
  // Samples txd once per half-bit-period-aligned tick; call sample() every
  // clock edge with the current txd line level and current cycle count.
  enum State { IDLE, START, DATA, STOP };
  State state = IDLE;
  uint64_t next_sample_cycle = 0;
  int bit_index = 0;
  uint8_t shift_reg = 0;

  std::vector<uint8_t> bytes_out;

  void sample(uint8_t txd, uint64_t cycle) {
    switch (state) {
      case IDLE:
        if (txd == 0) {  // falling edge -> start bit begins
          // Sample mid-bit for reliability against edge jitter.
          next_sample_cycle = cycle + CYCLES_PER_BIT / 2;
          state = START;
        }
        break;
      case START:
        if (cycle >= next_sample_cycle) {
          if (txd == 0) {

            // Confirmed start bit; schedule first data bit sample.
            next_sample_cycle = cycle + CYCLES_PER_BIT;
            bit_index = 0;

            shift_reg = 0;
            state = DATA;
          } else {
            // False start (glitch) -> back to idle.

            state = IDLE;

          }
        }
        break;
      case DATA:
        if (cycle >= next_sample_cycle) {
          shift_reg |= (txd & 1) << bit_index;  // LSB first
          bit_index++;
          next_sample_cycle = cycle + CYCLES_PER_BIT;
          if (bit_index == 8) {
            state = STOP;
          }
        }

        break;
      case STOP:
        if (cycle >= next_sample_cycle) {
          if (txd == 1) {
            bytes_out.push_back(shift_reg);
          } else {
            std::fprintf(stderr,
                         "[uart] WARNING: framing error, expected stop bit "
                         "high, got low at cycle %llu (byte 0x%02x)\n",
                         (unsigned long long)cycle, shift_reg);
          }

          state = IDLE;
        }
        break;
    }
  }

  std::string as_string() const {
    return std::string(bytes_out.begin(), bytes_out.end());
  }

};

// ---------------------------------------------------------------------

static void print_cpi_report(const CpiCounter& cpi, uint64_t cycle, uint64_t reset_cycles) {
  std::printf("---- CPI ----\n");
  std::printf("Instructions retired : %llu\n", (unsigned long long)cpi.instr_count);
  std::printf("Cycles (post-reset)  : %llu\n", (unsigned long long)(cycle - reset_cycles));
  if (cpi.instr_count > 0) {
    double cpi_val = (double)(cycle - reset_cycles) / (double)cpi.instr_count;
    std::printf("CPI (raw, includes any trailing halt loop) : %.4f\n", cpi_val);
  }
  if (cpi.halt_detected) {
    uint64_t real_cycles = cpi.cycle_at_halt - reset_cycles;
    std::printf("Halt loop detected at pc=0x%08x, cycle %llu\n",
               cpi.prev_pc, (unsigned long long)cpi.cycle_at_halt);
    std::printf("Instructions (excl. halt loop) : %llu\n",
               (unsigned long long)cpi.instr_count_at_halt);
    std::printf("Cycles (excl. halt loop)       : %llu\n", (unsigned long long)real_cycles);
    if (cpi.instr_count_at_halt > 0) {
      double real_cpi = (double)real_cycles / (double)cpi.instr_count_at_halt;
      std::printf("CPI (excl. halt loop)          : %.4f  <- use this one\n", real_cpi);
    }
  } else {
    std::printf("(No halt loop detected -- simulation likely ended before reaching one,\n");
    std::printf(" or the program doesn't end in a 1-cycle self-loop. Raw CPI above is\n");
    std::printf(" the number to use in that case.)\n");
  }
}

static void print_repeat_pc_report(const CpiCounter& cpi) {
  if (cpi.repeat_counts.empty()) {
    std::printf("No repeated-PC cycles observed.\n");
    return;
  }
  std::printf("Total repeat-PC cycles : %llu\n", (unsigned long long)cpi.total_repeat_cycles);
  std::printf("First repeat at cycle  : %llu\n", (unsigned long long)cpi.first_repeat_cycle);
  std::printf("Distinct PCs affected  : %zu\n", cpi.repeat_counts.size());
  std::printf("Breakdown (pc -> repeat count), largest first:\n");

  // Copy into a vector to sort by count descending -- std::map is sorted
  // by key (address), which isn't what we want to scan first.
  std::vector<std::pair<uint32_t, uint64_t>> sorted(cpi.repeat_counts.begin(),

                                                     cpi.repeat_counts.end());
  std::sort(sorted.begin(), sorted.end(),

           [](const auto& a, const auto& b) { return a.second > b.second; });


  size_t shown = 0;
  for (const auto& kv : sorted) {
    uint32_t pc = kv.first;
    uint64_t count = kv.second;
    std::printf("  pc=0x%08x : %llu repeat cycle(s)%s\n", pc, (unsigned long long)count,
               count > 1000 ? "  <- likely the expected final halt/spin loop" : "");
    shown++;
    if (shown >= 20) {
      std::printf("  ... (%zu more distinct PCs not shown)\n", sorted.size() - shown);
      break;

    }
  }

}


int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);
  Verilated::traceEverOn(true);

  // ---- Parse args: default hello-world check, or --dump <file> <cycles> ----
  bool dump_mode = false;
  std::string dump_path;
  uint64_t max_cycles = DEFAULT_MAX_CYCLES;


  for (int i = 1; i < argc; i++) {
    if (std::strcmp(argv[i], "--dump") == 0 && i + 2 < argc) {
      dump_mode = true;
      dump_path = argv[i + 1];
      max_cycles = std::strtoull(argv[i + 2], nullptr, 10);
      i += 2;
    }

  }

  if (dump_mode) {
    std::printf("Dump mode: writing UART bytes to '%s', running up to %llu cycles\n",

                dump_path.c_str(), (unsigned long long)max_cycles);
  }


  VSoC* dut = new VSoC;
  VerilatedVcdC* tfp = nullptr;
  if (!dump_mode) {
    // Skip VCD tracing in dump mode -- a full Mandelbrot render can run
    // for millions of cycles, and dumping every signal every cycle would
    // make the waveform file enormous and slow the sim down substantially.
    // If you need to debug the Mandelbrot run itself, re-enable this and
    // expect a large waveform.vcd.
    tfp = new VerilatedVcdC;
    dut->trace(tfp, 99);
    tfp->open("waveform.vcd");
  }


  dut->clk = 0;
  dut->reset = 1;

  dut->RXD = 1;  // idle-high, unused by this program but keep it sane


  UartDecoder decoder;
  CpiCounter cpi;
  uint64_t cycle = 0;
  vluint64_t sim_time = 0;

  // Hold reset for a handful of cycles before releasing.
  const uint64_t RESET_CYCLES = 10;

  FILE* dump_file = nullptr;
  size_t dump_bytes_written = 0;
  if (dump_mode) {
    dump_file = std::fopen(dump_path.c_str(), "wb");
    if (!dump_file) {
      std::fprintf(stderr, "ERROR: could not open '%s' for writing\n", dump_path.c_str());
      return 1;
    }
  }

  for (cycle = 0; cycle < max_cycles; cycle++) {
    if (cycle == RESET_CYCLES) {
      dut->reset = 0;
    }

    // Rising edge
    dut->clk = 1;
    dut->eval();
    if (tfp) tfp->dump(sim_time);
    sim_time += (vluint64_t)(CLK_PERIOD_NS / 2);


    size_t before = decoder.bytes_out.size();
    decoder.sample(dut->TXD, cycle);
    cpi.sample(dut->pc_sig, dut->reset != 0, cycle);

    // In dump mode, stream each newly-decoded byte straight to disk so we
    // don't hold the whole (potentially large) output in memory.
    if (dump_mode && decoder.bytes_out.size() > before) {
      uint8_t b = decoder.bytes_out.back();

      std::fputc(b, dump_file);
      dump_bytes_written++;
      if (dump_bytes_written % 10000 == 0) {
        std::printf("  ... %zu bytes received (cycle %llu)\n",
                    dump_bytes_written, (unsigned long long)cycle);
        std::fflush(stdout);
      }
    }

    // Falling edge
    dut->clk = 0;
    dut->eval();
    if (tfp) tfp->dump(sim_time);
    sim_time += (vluint64_t)(CLK_PERIOD_NS / 2);


    if (!dump_mode) {

      // Early-exit once we've captured as many bytes as expected, plus a
      // small settle margin, to keep hello-world runs fast.
      if (decoder.bytes_out.size() >= EXPECTED.size()) {

        static uint64_t settle_until = 0;
        if (settle_until == 0) settle_until = cycle + CYCLES_PER_BIT * 2;
        if (cycle >= settle_until) break;
      }
    }
  }

  if (tfp) tfp->close();
  dut->final();

  if (dump_mode) {
    std::fclose(dump_file);

    std::printf("---- Dump complete ----\n");
    std::printf("Cycles simulated : %llu%s\n", (unsigned long long)cycle,
               cycle >= max_cycles ? " (hit cycle limit, program may not have finished)" : "");
    std::printf("Bytes written    : %zu -> %s\n", dump_bytes_written, dump_path.c_str());

    print_cpi_report(cpi, cycle, RESET_CYCLES);
    std::printf("---- Repeat-PC report ----\n");
    print_repeat_pc_report(cpi);
    delete dut;

    delete tfp;
    return 0;
  }

  std::string received = decoder.as_string();

  std::printf("---- UART RX summary ----\n");

  std::printf("Cycles simulated : %llu\n", (unsigned long long)cycle);
  std::printf("Bytes received   : %zu\n", decoder.bytes_out.size());
  std::printf("Received (raw)   : \"");
  for (unsigned char c : received) {
    if (c == '\r') std::printf("\\r");

    else if (c == '\n') std::printf("\\n");
    else if (c >= 32 && c < 127) std::putchar(c);
    else std::printf("\\x%02x", c);
  }

  std::printf("\"\n");

  bool pass = (received == EXPECTED);
  std::printf("Expected         : \"hello from rv32i\\r\\n\"\n");
  std::printf("Result           : %s\n", pass ? "PASS" : "FAIL");

  print_cpi_report(cpi, cycle, RESET_CYCLES);
  std::printf("---- Repeat-PC report ----\n");
  print_repeat_pc_report(cpi);

  delete dut;
  delete tfp;

  return pass ? 0 : 1;
}
