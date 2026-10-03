package fifo_seq_item_pkg;
  import uvm_pkg::*;
  import fifo_shared_pkg::*;
  `include "uvm_macros.svh"

  class fifo_seq_item extends uvm_sequence_item;
    `uvm_object_utils(fifo_seq_item)
    
    rand logic rst_n;
    rand logic wr_en;
    rand logic rd_en;
    rand logic [FIFO_WIDTH-1:0] data_in;

    logic [FIFO_WIDTH-1:0] data_out;
    logic wr_ack, overflow, full, empty, almostfull, almostempty, underflow;

    int RD_EN_ON_DIST;
    int WR_EN_ON_DIST;

    constraint reset_c { rst_n dist {0 := 5, 1 := 95}; }
    constraint wr_en_c { wr_en dist {1 := WR_EN_ON_DIST, 0 := (100 - WR_EN_ON_DIST)}; }
    constraint rd_en_c { rd_en dist {1 := RD_EN_ON_DIST, 0 := (100 - RD_EN_ON_DIST)}; }

    function new(string name = "fifo_seq_item");
      super.new(name);
      RD_EN_ON_DIST = 30;
      WR_EN_ON_DIST = 70;
    endfunction

    function string convert2string();
      return $sformatf("rst_n=%0b wr=%0b rd=%0b din=%0h dout=%0h full=%0b empty=%0b", 
                        rst_n, wr_en, rd_en, data_in, data_out, full, empty);
    endfunction
  endclass
endpackage