package fifo_monitor_pkg;
  import uvm_pkg::*;
  import fifo_seq_item_pkg::*;
  `include "uvm_macros.svh"

  class fifo_monitor extends uvm_monitor;
    `uvm_component_utils(fifo_monitor)

    virtual FIFO_if fifo_vif;
    fifo_seq_item rsp_seq_item;
    uvm_analysis_port #(fifo_seq_item) mon_ap;

    function new(string name = "fifo_monitor" , uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      mon_ap = new("mon_ap", this);
    endfunction

    task run_phase(uvm_phase phase);
      super.run_phase(phase);
      forever begin
        rsp_seq_item = fifo_seq_item::type_id::create("rsp_seq_item");
        
        // Wait for driving to settle on the negedge
        @(negedge fifo_vif.clk); 
        
        // Sample exact state of inputs and outputs
        rsp_seq_item.rst_n = fifo_vif.rst_n;
        rsp_seq_item.wr_en = fifo_vif.wr_en;
        rsp_seq_item.rd_en = fifo_vif.rd_en;
        rsp_seq_item.data_in = fifo_vif.data_in;
        rsp_seq_item.data_out = fifo_vif.data_out;
        rsp_seq_item.wr_ack = fifo_vif.wr_ack;
        rsp_seq_item.overflow = fifo_vif.overflow;
        rsp_seq_item.full = fifo_vif.full;
        rsp_seq_item.empty = fifo_vif.empty;
        rsp_seq_item.almostfull = fifo_vif.almostfull;
        rsp_seq_item.almostempty = fifo_vif.almostempty;
        rsp_seq_item.underflow = fifo_vif.underflow;
        
        mon_ap.write(rsp_seq_item);   //broadcast the sampled data to the analysis port coverage and scoreboard
      end
    endtask
  endclass
endpackage