package fifo_main_seq_pkg;
  import uvm_pkg::*;
  import fifo_seq_item_pkg::*;
  import fifo_reset_seq_pkg::*;
  import fifo_write_only_seq_pkg::*;
  import fifo_read_only_seq_pkg::*;
  import fifo_write_read_seq_pkg::*;
  `include "uvm_macros.svh"

  class fifo_main_seq extends uvm_sequence #(fifo_seq_item);
    `uvm_object_utils(fifo_main_seq)
    
    fifo_reset_seq rst_seq;
    fifo_write_only_seq wr_seq;
    fifo_read_only_seq rd_seq;
    fifo_write_read_seq wr_rd_seq;

    function new(string name = "fifo_main_seq");
      super.new(name);
    endfunction

    task body;
      rst_seq = fifo_reset_seq::type_id::create("rst_seq");
      wr_seq = fifo_write_only_seq::type_id::create("wr_seq");
      rd_seq = fifo_read_only_seq::type_id::create("rd_seq");
      wr_rd_seq = fifo_write_read_seq::type_id::create("wr_rd_seq");

      rst_seq.start(m_sequencer);
      wr_seq.start(m_sequencer);      // Fills to trigger FULL & OVERFLOW
      rd_seq.start(m_sequencer);      // Drains to trigger EMPTY & UNDERFLOW
      wr_rd_seq.start(m_sequencer);   // Simultaneous logic boundary testing
    endtask
  endclass
endpackage