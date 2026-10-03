# UVM FIFO Verification Environment

[![Language](https://img.shields.io/badge/language-SystemVerilog-1683C5)](https://ieeexplore.ieee.org/document/8299595) [![Methodology](https://img.shields.io/badge/methodology-UVM-6A1B9A)](https://accellera.org/downloads/standards/uvm) [![Simulator](https://img.shields.io/badge/simulator-QuestaSim%202021.1-0A6F9E)](https://eda.sw.siemens.com/en-US/ic/questa/verification/)

Complete UVM verification environment for this repository's synchronous FIFO RTL: **16-bit data** and **depth 8**. It exercises reset, valid and boundary reads/writes, overflow/underflow, data ordering, pointer wraparound, flag thresholds, and simultaneous requests. The repository includes runnable QuestaSim scripts, an editable testbench diagram, a FIFO_1–FIFO_13 verification plan, and recorded coverage evidence.

![UVM testbench architecture](docs/UVM_FIFO_Testbench.png)

## Design under test

`code/FIFO.sv` has separate clocked write/overflow, read/underflow, and count processes. `top` supplies a 10 ns clock. Reset is active-low (`negedge f_if.rst_n`).

| Item | Implementation |
|---|---|
| Parameters | `FIFO_WIDTH=16`, `FIFO_DEPTH=8` |
| Storage / state | `mem[0:FIFO_DEPTH-1]`, 3-bit `wr_ptr` and `rd_ptr`, 4-bit `count` |
| Inputs | `clk`, `rst_n`, `wr_en`, `rd_en`, `data_in` |
| Outputs | `data_out`, `wr_ack`, `overflow`, `underflow`, `full`, `empty`, `almostfull`, `almostempty` |
| Thresholds | full: 8; empty: 0; almost-full: 7; almost-empty: 1 |

A valid write stores `data_in`, acknowledges it, and advances `wr_ptr`; a write at full is rejected and flags overflow. A valid read returns `mem[rd_ptr]` and advances `rd_ptr`; a read at empty flags underflow. For concurrent requests, the RTL accepts only the write when empty, only the read when full, and otherwise keeps count unchanged.

`code/fifo_if.sv` provides `FIFO_if` and its `DUT` modport, which gives the DUT the clock/control/data inputs and exposes all responses.

## UVM hierarchy and data flow

`top.sv` creates `f_if` and `DUT`, binds SVA into `FIFO`, registers the virtual interface as `FIFO_IF`, and runs `fifo_test`.

```text
top
├── f_if : FIFO_if
├── DUT : FIFO
│   └── fifo_assert_inst : fifo_assertions (bound)
└── uvm_test_top : fifo_test
    └── fifoenv : fifo_env
        ├── agt : fifo_agent
        │   ├── sqr : fifo_sequencer
        │   ├── drv : fifo_driver ──► f_if ──► DUT
        │   └── mon : fifo_monitor ──► agt_ap
        ├── sb  : fifo_scoreboard  ◄─────────┘
        └── cov : fifo_coverage    ◄─────────┘
```

The editable diagram is [docs/UVM_FIFO_Testbench.drawio](docs/UVM_FIFO_Testbench.drawio).

| Component | Responsibility in this implementation |
|---|---|
| `fifo_test` | Gets `FIFO_IF`, distributes `fifo_config`, manages the run objection, and starts `fifo_main_seq`. |
| `fifo_env` | Creates/connects agent, scoreboard, and coverage collector. |
| `fifo_agent` | Creates sequencer/driver/monitor, connects sequence traffic, and broadcasts monitor items. |
| `fifo_driver` | Drives `rst_n`, enables, and input data, then completes items on a negedge. |
| `fifo_monitor` | Samples every input, response, and flag on a negedge and broadcasts a `fifo_seq_item`. |
| `fifo_scoreboard` | Queue reference model and `data_out` checker. |
| `fifo_coverage` | Analysis-FIFO consumer that samples the covergroup. |

## Stimulus, reference model, and assertions

### Transactions and sequences

`fifo_seq_item` randomizes `rst_n`, `wr_en`, `rd_en`, and 16-bit `data_in`. Default distributions are reset asserted 5%, write enabled 70%, and read enabled 30%; the monitor populates response/flag fields.

`fifo_main_seq` runs these child sequences sequentially:

| Sequence | Actual stimulus |
|---|---|
| `fifo_reset_seq` | One directed item: active-low reset with enables/data cleared. |
| `fifo_write_only_seq` | 15 randomized writes (`rst_n=1`, write=1, read=0), targeting fill/full/overflow. |
| `fifo_read_only_seq` | 15 randomized reads (`rst_n=1`, write=0, read=1), targeting drain/empty/underflow. |
| `fifo_write_read_seq` | 50 forced simultaneous requests, then 2,000 unconstrained randomized items with reset randomization enabled. |

### Scoreboard / reference FIFO

`fifo_scoreboard` uses `mem_ref[$]` as the expected FIFO. Reset deletes the queue. From monitored enables and its current depth it derives legal push/pop behavior, including the RTL's empty/full simultaneous-request rules. Accepted writes push `data_in`; accepted reads pop the front and compare it against `item.data_out` using `!==`. Matches increment `correct_count`; mismatches produce `SB_FAIL` and increment `error_count`.

### Bound SVA and sequential coverage

`fifo_assertions.sv` is bound in `top.sv`, receiving `count`, `wr_ptr`, and `rd_ptr` from the DUT. It contains reset final assertions plus concurrent properties for:

- `wr_ack`, overflow, and underflow;
- empty/full/almost-full/almost-empty thresholds;
- write and read pointer wraparound;
- count and pointer limits;
- no write acknowledge on a full FIFO; and
- simultaneous read/write count behavior at empty, full, and intermediate occupancy.

The scenario properties are also used as 13 `cover property` directives.

## Functional coverage and verification plan

`fifo_coverage` defines coverpoints for `wr_en`, `rd_en`, `full`, `empty`, `almostfull`, `almostempty`, `overflow`, `underflow`, and `wr_ack`. It contains seven crosses: full, empty, almost-full, almost-empty, overflow, underflow, and acknowledge against request enables.

The implementation uses `ignore_bins` for combinations impossible with post-edge sampling: full with read enabled, overflow without write, underflow without read, and acknowledge without write. The detailed FIFO_1–FIFO_13 mapping is in [docs/FIFO_UVM_Verification_Plan.xlsx](docs/FIFO_UVM_Verification_Plan.xlsx): reset, valid write, overflow, underflow, flags, wraparound, thresholds, concurrent operations, ordering, and no acknowledge on full are traced to sequences, coverage, and checks.

## Run with QuestaSim

Requirements: QuestaSim **2021.1**, SystemVerilog/UVM support, and coverage support. In QuestaSim, make `code/` the working directory.

```tcl
do run.do
```

`run.do` creates/maps `work`, compiles `src_files.list` with `vlog +cover`, starts `work.top` with `-coverage -voptargs=+acc -classdebug -uvmcontrol=all`, adds interface and DUT-internal waves, and runs to completion.

Then generate coverage artifacts:

```tcl
do save_cov.do
```

This saves `fifo_tb.ucdb` (all coverage) and `fifo_code.ucdb` (DUT-only) and writes `code_coverage_rpt.txt`, `functional_coverage_rpt.txt`, and `assertion_coverage_rpt.txt`. Generated files in `code/` are ignored by Git; retain selected evidence by copying it to `docs/coverage_reports/`.

## Debug and waveform workflow

The supplied script adds `/top/f_if/*` plus `/top/DUT/count`, `/top/DUT/wr_ptr`, and `/top/DUT/rd_ptr`. Capture reset, full/overflow, empty/underflow, threshold, wrap, and simultaneous-operation regions, correlating request/response signals with internal occupancy.

### `run 0` and UVM Details

UVM components are dynamically constructed, so they cannot be browsed immediately after `vsim`. Enable recording, build at time zero, add UVM objects, then continue:

```tcl
vsim -coverage -voptargs=+acc work.top -classdebug -uvmcontrol=all +UVM_TR_RECORD
run 0
add wave /top/f_if/*
add wave /uvm_root/uvm_test_top/fifoenv/agt/sqr
run -all
```

`run 0` executes elaboration/phase setup while holding simulation time at 0 ns; this permits browsing `uvm_test_top.fifoenv.agt.sqr` and adding its recorded transactions. For a focused debug session: `restart`, `run 0`, add waves, run a bounded interval such as `run 100 ns`, and inspect **View → UVM Details** before continuing or restarting.

| Debug flag | Use |
|---|---|
| `+UVM_TR_RECORD` | Transaction streams and sequence visualization. |
| `+UVM_OBJECTION_TRACE` | Unexpected finish or objection lifecycle issues. |
| `+UVM_CONFIG_DB_TRACE` | Virtual-interface/configuration lookup failures. |
| `+UVM_PHASE_TRACE` | Identifying the phase where progress stops. |

For temporary transcript diagnosis, add this to `fifo_test` (it is not in the checked-in test):

```systemverilog
function void end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);
  uvm_top.print_topology();
  factory.print();
endfunction
```

`uvm_top.print_topology()` confirms the constructed hierarchy; `factory.print()` lists registered types and overrides.

## Repository structure

```text
UVM_FIFO_Project/
├── code/
│   ├── FIFO.sv, fifo_if.sv, top.sv
│   ├── fifo_assertions.sv, fifo_shared_pkg.sv, fifo_config.sv
│   ├── fifo_seq_item.sv, fifo_*_seq.sv
│   ├── fifo_sequencer.sv, fifo_driver.sv, fifo_monitor.sv, fifo_agent.sv
│   ├── fifo_scoreboard.sv, fifo_coverage.sv, fifo_env.sv, fifo_test.sv
│   ├── src_files.list
│   ├── run.do
│   └── save_cov.do
├── docs/
│   ├── FIFO_UVM_Verification_Plan.xlsx
│   ├── UVM_FIFO_Testbench.drawio
│   ├── UVM_FIFO_Testbench.png
│   └── coverage_reports/
│       ├── code_coverage_rpt.txt
│       ├── functional_coverage_rpt.txt
│       └── assertion_coverage_rpt.txt
├── .gitattributes
├── .gitignore
└── README.md
```

## Recorded results

The checked-in reports record the following evidence; rerun the supplied scripts after any RTL/UVM/simulator setting change.

| Evidence | Recorded result |
|---|---|
| Functional coverage | **100.00%** (66/66 covergroup bins) |
| Sequential-domain coverage | **18/18 assertions** pass with zero failures; **13/13 cover directives** covered |
| `FIFO.sv` code coverage | Statement 100%, branch 100%, toggle 100%, condition 90%; overall **98.33%** |

The report's two uncovered condition rows are in overflow/underflow guards and are mutually constrained by their enclosing `else` branches, not missing FIFO scenarios.

## Limitations

- This environment covers one synchronous configuration only: 16-bit width and depth 8.
- It uses one active agent; it does not provide passive-agent, multi-clock, or asynchronous-FIFO modes.
- `fifo_main_seq` is hard-coded in `fifo_test`; supplied code does not expose test selection or seed control through plusargs.
- `run.do` adds signal-level waveforms. Sequence transaction blocks require the optional `+UVM_TR_RECORD` workflow above.

## Author

Ahmed Wael Sadek El Sawy
