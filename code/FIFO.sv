module FIFO (FIFO_if.DUT f_if);
  parameter FIFO_WIDTH = 16;
  parameter FIFO_DEPTH = 8;
  localparam max_fifo_addr = $clog2(FIFO_DEPTH);

  reg [FIFO_WIDTH-1:0] mem [FIFO_DEPTH-1:0];
  reg [max_fifo_addr-1:0] wr_ptr, rd_ptr;
  reg [max_fifo_addr:0] count;

  // Sequential Write & Overflow Logic
  always @(posedge f_if.clk or negedge f_if.rst_n) begin
    if (!f_if.rst_n) begin
      wr_ptr <= 0;
      f_if.wr_ack <= 0;
      f_if.overflow <= 0;
    end
    else if (f_if.wr_en && count < FIFO_DEPTH) begin
      mem[wr_ptr] <= f_if.data_in;
      f_if.wr_ack <= 1;
      f_if.overflow <= 0;
      wr_ptr <= wr_ptr + 1;
    end
    else begin 
      f_if.wr_ack <= 0; 
      if (f_if.full & f_if.wr_en)
        f_if.overflow <= 1;
      else
        f_if.overflow <= 0;
    end
  end

  // Sequential Read & Underflow Logic
  always @(posedge f_if.clk or negedge f_if.rst_n) begin
    if (!f_if.rst_n) begin
      rd_ptr <= 0;
      f_if.underflow <= 0;
    end
    else if (f_if.rd_en && count != 0) begin
      f_if.data_out <= mem[rd_ptr];
      f_if.underflow <= 0;
      rd_ptr <= rd_ptr + 1;
    end
    else begin
      if (f_if.empty & f_if.rd_en)
        f_if.underflow <= 1;
      else
        f_if.underflow <= 0;
    end
  end

  // Counter Logic handling simultaneous read/writes
  always @(posedge f_if.clk or negedge f_if.rst_n) begin
    if (!f_if.rst_n) begin
      count <= 0;
    end
    else begin
      if ( ({f_if.wr_en, f_if.rd_en} == 2'b10 && !f_if.full) || 
           ({f_if.wr_en, f_if.rd_en} == 2'b11 && f_if.empty) ) 
        count <= count + 1;
      else if ( ({f_if.wr_en, f_if.rd_en} == 2'b01 && !f_if.empty) || 
                ({f_if.wr_en, f_if.rd_en} == 2'b11 && f_if.full) )
        count <= count - 1;
    end
  end

  // Combinational Flags
  assign f_if.full = (count == FIFO_DEPTH) ? 1 : 0;
  assign f_if.empty = (count == 0) ? 1 : 0;
  assign f_if.almostfull = (count == FIFO_DEPTH-1) ? 1 : 0; 
  assign f_if.almostempty = (count == 1) ? 1 : 0;
endmodule