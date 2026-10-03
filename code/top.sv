import uvm_pkg::*;
import fifo_test_pkg::*;
`include "uvm_macros.svh"

module top();
  bit clk;

  initial begin
    clk <= 0;
    forever #5 clk = ~clk;
  end

  FIFO_if f_if (clk);
  
  FIFO DUT (f_if);

  // Bind assertions directly into the FIFO module, passing the interface 
  // and mapping the internal signals (count, wr_ptr, rd_ptr)
  bind FIFO fifo_assertions fifo_assert_inst (
    .f_if(f_if),
    .count(count),
    .wr_ptr(wr_ptr),
    .rd_ptr(rd_ptr)
  );

  initial begin
    uvm_config_db#(virtual FIFO_if)::set(null, "uvm_test_top", "FIFO_IF", f_if);
    run_test("fifo_test");
  end
endmodule