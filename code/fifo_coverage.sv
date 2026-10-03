package fifo_coverage_pkg;
  import uvm_pkg::*;
  import fifo_seq_item_pkg::*;
  `include "uvm_macros.svh"

  class fifo_coverage extends uvm_component;
    `uvm_component_utils(fifo_coverage)
    
    uvm_analysis_export #(fifo_seq_item) cov_export;
    uvm_tlm_analysis_fifo #(fifo_seq_item) cov_fifo;
    fifo_seq_item seq_item_cov;

    covergroup cvr_gp;
      wr_en_cp: coverpoint seq_item_cov.wr_en;
      rd_en_cp: coverpoint seq_item_cov.rd_en;
      full_cp: coverpoint seq_item_cov.full;
      empty_cp: coverpoint seq_item_cov.empty;
      almostfull_cp: coverpoint seq_item_cov.almostfull;
      almostempty_cp: coverpoint seq_item_cov.almostempty;
      overflow_cp: coverpoint seq_item_cov.overflow;
      underflow_cp: coverpoint seq_item_cov.underflow;
      wr_ack_cp: coverpoint seq_item_cov.wr_ack;

      // Crosses of wr_en/rd_en with the DUT flags. The monitor samples the flags AFTER the clock edge,
      // so the bins excluded below can never happen for any stimulus (see the exclusion table in the report).
      cross_full: cross wr_en_cp, rd_en_cp, full_cp {
        // a read always leaves the FIFO not full (count-1, or unchanged for wr+rd), so full=1 with rd_en=1 is impossible
        ignore_bins full_with_read = binsof(rd_en_cp) intersect {1} && binsof(full_cp) intersect {1};
      }
      cross_empty: cross wr_en_cp, rd_en_cp, empty_cp;
      cross_almostfull: cross wr_en_cp, rd_en_cp, almostfull_cp;
      cross_almostempty: cross wr_en_cp, rd_en_cp, almostempty_cp;
      cross_overflow: cross wr_en_cp, rd_en_cp, overflow_cp {
        // overflow is only raised in response to a write attempt
        ignore_bins overflow_without_write = binsof(wr_en_cp) intersect {0} && binsof(overflow_cp) intersect {1};
      }
      cross_underflow: cross wr_en_cp, rd_en_cp, underflow_cp {
        // underflow is only raised in response to a read attempt
        ignore_bins underflow_without_read = binsof(rd_en_cp) intersect {0} && binsof(underflow_cp) intersect {1};
      }
      cross_wr_ack: cross wr_en_cp, rd_en_cp, wr_ack_cp {
        // wr_ack is only raised in response to a write request
        ignore_bins ack_without_write = binsof(wr_en_cp) intersect {0} && binsof(wr_ack_cp) intersect {1};
      }
    endgroup

    function new(string name = "fifo_coverage" , uvm_component parent = null);
      super.new(name, parent);
      cvr_gp = new();
    endfunction

    function void build_phase(uvm_phase phase); 
      super.build_phase(phase);
      cov_export = new("cov_export", this);
      cov_fifo = new("cov_fifo", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      cov_export.connect(cov_fifo.analysis_export); //connect the analysis export to the analysis fifo
    endfunction

    task run_phase(uvm_phase phase);
      super.run_phase(phase);
      forever begin
        cov_fifo.get(seq_item_cov); //get next item from the analysis fifo from monitor
        cvr_gp.sample(); //sample the covergroup with the data from the monitor
      end
    endtask
  endclass
endpackage