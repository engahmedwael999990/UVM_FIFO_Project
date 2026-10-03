package fifo_read_only_seq_pkg;
  import uvm_pkg::*;
  import fifo_seq_item_pkg::*;
  `include "uvm_macros.svh"

  class fifo_read_only_seq extends uvm_sequence #(fifo_seq_item);
    `uvm_object_utils(fifo_read_only_seq)
    fifo_seq_item req;

    function new(string name = "fifo_read_only_seq");
      super.new(name);
    endfunction

    task body;
      repeat(15) begin
        req = fifo_seq_item::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {rst_n == 1; wr_en == 0; rd_en == 1;});
        finish_item(req);
      end
    endtask
  endclass
endpackage