package fifo_reset_seq_pkg;
  import uvm_pkg::*;
  import fifo_seq_item_pkg::*;
  `include "uvm_macros.svh"

  class fifo_reset_seq extends uvm_sequence #(fifo_seq_item);
    `uvm_object_utils(fifo_reset_seq)
    fifo_seq_item req;

    function new(string name = "fifo_reset_seq");
      super.new(name);
    endfunction

    task body;
      req = fifo_seq_item::type_id::create("req");
      start_item(req);
      req.rst_n = 0;
      req.wr_en = 0;
      req.rd_en = 0;
      req.data_in = 0;
      finish_item(req);
    endtask
  endclass
endpackage