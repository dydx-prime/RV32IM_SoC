# verifying rv32i core.

Should have implemented traps before running this. I honestly don't fully understand the procedure, but it is making more sense now.

# TODO

each test run takes a while; need to find a way to make it faster (low priority)
re-implement rv32i with trap handling, should lead to easier testing.
5 stage pipeline.
M extension.

# COMMANDS

- make run
    - starts the verification test. must have sourced OSS CAD Suite prior to running or it will fail.

- bash display_checks.sh
    - will print the PASS/FAIL instructions from previous run.

- sby -f <path to check>
    - example: sby -f checks/reg_ch0.sby will run reg_ch0 specifically, rather than testing all instructions, good for testing fixes for a particular instruction

# Files/Directories

- my_core.sv
    - for verification, all modules are placed in a single file, exposing rvfi signals.
- wrapper.sv
    - wrapper required to run verification
- checks/
    - contains instructions to verify as well as data from last verification run, such as logs and waveforms
- checks.cfg
    - configuration file for setting up verification environment, and stimuli
