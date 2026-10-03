package fifo_write_read_seq_pkg;
  import uvm_pkg::*;
  import fifo_seq_item_pkg::*;
  `include "uvm_macros.svh"

  class fifo_write_read_seq extends uvm_sequence #(fifo_seq_item);
    `uvm_object_utils(fifo_write_read_seq)
    fifo_seq_item req;

    function new(string name = "fifo_write_read_seq");
      super.new(name);
    endfunction

    task body;
      repeat(50) begin
        req = fifo_seq_item::type_id::create("req");
        start_item(req);
        // Force both high to test simultaneous logic boundaries
        assert(req.randomize() with {rst_n == 1; wr_en == 1; rd_en == 1;});
        finish_item(req);
      end
      
      // Standard random phase: reset is NOT forced high, so reset_c (5%) asserts rst_n at random
      repeat(2000) begin
        req = fifo_seq_item::type_id::create("req");
        start_item(req);
        assert(req.randomize());
        finish_item(req);
      end
    endtask
  endclass
endpackage