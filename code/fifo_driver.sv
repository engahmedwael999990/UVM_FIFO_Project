package fifo_driver_pkg;
  import uvm_pkg::*;
  import fifo_seq_item_pkg::*;
  import fifo_config_pkg::*;
  `include "uvm_macros.svh"

  class fifo_driver extends uvm_driver#(fifo_seq_item);
    `uvm_component_utils(fifo_driver)

    virtual FIFO_if fifo_vif;
    fifo_seq_item req;

    function new(string name = "fifo_driver" , uvm_component parent = null);
      super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
      super.run_phase(phase);
      forever begin
        req = fifo_seq_item::type_id::create("req");
        seq_item_port.get_next_item(req);
        
        fifo_vif.rst_n = req.rst_n;
        fifo_vif.wr_en = req.wr_en;
        fifo_vif.rd_en = req.rd_en;
        fifo_vif.data_in = req.data_in;
        
        @(negedge fifo_vif.clk);
        seq_item_port.item_done();
      end
    endtask
  endclass
endpackage