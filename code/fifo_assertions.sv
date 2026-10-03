module fifo_assertions (
  FIFO_if.DUT f_if,
  input logic [3:0] count,
  input logic [2:0] wr_ptr,
  input logic [2:0] rd_ptr
);
  parameter FIFO_DEPTH = 8;

  always_comb begin
    if (!f_if.rst_n) begin
      a_reset_count: assert final (count == 0);
      a_reset_wr_ptr: assert final (wr_ptr == 0);
      a_reset_rd_ptr: assert final (rd_ptr == 0);
      a_reset_flags: assert final (!f_if.wr_ack && !f_if.overflow && !f_if.underflow);
    end
  end

  property p_wr_ack; @(posedge f_if.clk) disable iff (!f_if.rst_n) (f_if.wr_en && !f_if.full) |=> f_if.wr_ack; endproperty
  property p_overflow; @(posedge f_if.clk) disable iff (!f_if.rst_n) (f_if.wr_en && f_if.full) |=> f_if.overflow; endproperty
  property p_underflow; @(posedge f_if.clk) disable iff (!f_if.rst_n) (f_if.rd_en && f_if.empty) |=> f_if.underflow; endproperty
  property p_empty; @(posedge f_if.clk) disable iff (!f_if.rst_n) (count == 0) |-> f_if.empty; endproperty
  property p_full; @(posedge f_if.clk) disable iff (!f_if.rst_n) (count == FIFO_DEPTH) |-> f_if.full; endproperty
  property p_almostfull; @(posedge f_if.clk) disable iff (!f_if.rst_n) (count == FIFO_DEPTH-1) |-> f_if.almostfull; endproperty
  property p_almostempty; @(posedge f_if.clk) disable iff (!f_if.rst_n) (count == 1) |-> f_if.almostempty; endproperty
  property p_wr_wrap; @(posedge f_if.clk) disable iff (!f_if.rst_n) (wr_ptr == FIFO_DEPTH-1 && f_if.wr_en && !f_if.full) |=> (wr_ptr == 0); endproperty
  property p_threshold; @(posedge f_if.clk) disable iff (!f_if.rst_n) (count <= FIFO_DEPTH) && (wr_ptr < FIFO_DEPTH) && (rd_ptr < FIFO_DEPTH); endproperty

  property p_rd_wrap; @(posedge f_if.clk) disable iff (!f_if.rst_n) (rd_ptr == FIFO_DEPTH-1 && f_if.rd_en && !f_if.empty) |=> (rd_ptr == 0); endproperty
  property p_no_ack_when_full; @(posedge f_if.clk) disable iff (!f_if.rst_n) (f_if.wr_en && f_if.full) |=> !f_if.wr_ack; endproperty
  // FIFO_11 : simultaneous wr_en & rd_en -> empty: only the write happens, full: only the read happens, otherwise count is unchanged
  property p_wr_rd_empty; @(posedge f_if.clk) disable iff (!f_if.rst_n) (f_if.wr_en && f_if.rd_en && f_if.empty) |=> (count == $past(count) + 1); endproperty
  property p_wr_rd_full;  @(posedge f_if.clk) disable iff (!f_if.rst_n) (f_if.wr_en && f_if.rd_en && f_if.full)  |=> (count == $past(count) - 1); endproperty
  property p_wr_rd_mid;   @(posedge f_if.clk) disable iff (!f_if.rst_n) (f_if.wr_en && f_if.rd_en && !f_if.empty && !f_if.full) |=> (count == $past(count)); endproperty

  assert property (p_wr_ack);
  assert property (p_overflow);
  assert property (p_underflow);
  assert property (p_empty);
  assert property (p_full);
  assert property (p_almostfull);
  assert property (p_almostempty);
  assert property (p_wr_wrap);
  assert property (p_threshold);
  assert property (p_rd_wrap);
  assert property (p_no_ack_when_full);
  assert property (p_wr_rd_empty);
  assert property (p_wr_rd_full);
  assert property (p_wr_rd_mid);

  // Cover directives (sequential domain coverage): prove each scenario was really exercised
  cover property (p_wr_ack);
  cover property (p_overflow);
  cover property (p_underflow);
  cover property (p_empty);
  cover property (p_full);
  cover property (p_almostfull);
  cover property (p_almostempty);
  cover property (p_wr_wrap);
  cover property (p_rd_wrap);
  cover property (p_no_ack_when_full);
  cover property (p_wr_rd_empty);
  cover property (p_wr_rd_full);
  cover property (p_wr_rd_mid);
 
endmodule