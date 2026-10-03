package fifo_scoreboard_pkg;
  import uvm_pkg::*;
  import fifo_seq_item_pkg::*;
  import fifo_shared_pkg::*;
  `include "uvm_macros.svh"

  class fifo_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(fifo_scoreboard)
    
    uvm_analysis_export #(fifo_seq_item) sb_export;
    uvm_tlm_analysis_fifo #(fifo_seq_item) sb_fifo;
    fifo_seq_item item;

    bit [FIFO_WIDTH-1:0] mem_ref [$];  //reference queue to store the expected data_out values
    bit [FIFO_WIDTH-1:0] data_out_ref; //reference data_out value to compare with DUT data_out
    int correct_count = 0;
    int error_count = 0;

    function new(string name = "fifo_scoreboard" , uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);  
      super.build_phase(phase);
      sb_export = new("sb_export", this);
      sb_fifo = new("sb_fifo", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      sb_export.connect(sb_fifo.analysis_export);
    endfunction
      
    task run_phase(uvm_phase phase);
      super.run_phase(phase);
      
      forever begin
        sb_fifo.get(item);
        
        if (!item.rst_n) begin
          mem_ref.delete();
        end else begin
          bit push_flag = 0;
          bit pop_flag = 0;

          // Simultaneous Read/Write logic
          if (item.wr_en && item.rd_en) begin
            if (mem_ref.size() == 0) push_flag = 1;
            else if (mem_ref.size() == FIFO_DEPTH) pop_flag = 1;
            else begin push_flag = 1; pop_flag = 1; end
          end else begin
            if (item.wr_en && mem_ref.size() < FIFO_DEPTH) push_flag = 1;
            if (item.rd_en && mem_ref.size() != 0) pop_flag = 1;
          end
          
          if (push_flag) mem_ref.push_back(item.data_in);
          if (pop_flag) begin
            data_out_ref = mem_ref.pop_front();
            
            if (item.data_out !== data_out_ref) begin
              error_count++;
              `uvm_error("SB_FAIL", $sformatf("Mismatch! Exp: %0h, Act: %0h", data_out_ref, item.data_out))
            end else begin
              correct_count++;
              `uvm_info("SB_PASS", $sformatf("Match! Out: %0h", item.data_out), UVM_HIGH)
            end
          end
        end
      end
    endtask

    function void report_phase(uvm_phase phase);
      super.report_phase(phase);
      `uvm_info("SB_REPORT", $sformatf("Scoreboard summary: correct = %0d, errors = %0d", correct_count, error_count), UVM_LOW)
    endfunction
  endclass
endpackage
