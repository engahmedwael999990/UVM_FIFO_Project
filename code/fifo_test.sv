package fifo_test_pkg;
  import uvm_pkg::*;
  import fifo_env_pkg::*;
  import fifo_config_pkg::*;
  import fifo_main_seq_pkg::*;
  `include "uvm_macros.svh"

  class fifo_test extends uvm_test;
    `uvm_component_utils(fifo_test)
    
    fifo_env fifoenv;
    fifo_config fifo_cfg;
    fifo_main_seq main_seq;

    function new(string name = "fifo_test" , uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      fifoenv = fifo_env::type_id::create("fifoenv" , this);
      fifo_cfg = fifo_config::type_id::create("fifo_cfg");
      main_seq = fifo_main_seq::type_id::create("main_seq");
      
      if (!uvm_config_db #(virtual FIFO_if)::get(this, "", "FIFO_IF", fifo_cfg.fifo_vif))
        `uvm_fatal("build phase", "Test - Unable to get interface")
      
      uvm_config_db #(fifo_config)::set(this, "*", "CFG", fifo_cfg);
    endfunction
    
    task run_phase(uvm_phase phase);
      super.run_phase(phase);
      phase.raise_objection(this);
      
      `uvm_info("TEST", "Starting FIFO Main Sequence...", UVM_LOW)
      main_seq.start(fifoenv.agt.sqr); 
      `uvm_info("TEST", "Finished FIFO Main Sequence.", UVM_LOW)
      
      phase.drop_objection(this);
    endtask
  endclass
endpackage