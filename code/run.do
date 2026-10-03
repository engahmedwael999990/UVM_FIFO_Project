vlib work
vmap work work
vlog +cover -f src_files.list
vsim -coverage -voptargs=+acc work.top -classdebug -uvmcontrol=all
add wave -divider {Interface}
add wave /top/f_if/*
add wave -divider {DUT internals}
add wave -radix unsigned /top/DUT/count /top/DUT/wr_ptr /top/DUT/rd_ptr
run -all
wave zoom full