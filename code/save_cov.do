# ============================================
# Step 2 : after the run breaks at $finish,
#          save the databases and write reports
#   usage:  do save_cov.do
# ============================================
# full database: design code coverage + covergroups + assertions
coverage save fifo_tb.ucdb
# design-only database (code coverage of the DUT, no testbench noise)
coverage save fifo_code.ucdb -du FIFO
quit -sim
# ---------- report 1 : code coverage (design only) ----------
vcover report fifo_code.ucdb -details -annotate -all -excluded -output code_coverage_rpt.txt
# ---------- report 2 : functional coverage (covergroups) ----------
vcover report fifo_tb.ucdb -cvg -details -output functional_coverage_rpt.txt
# ---------- report 3 : sequential domain coverage (assertions + cover directives) ----------
vcover report fifo_tb.ucdb -assert -directive -details -output assertion_coverage_rpt.txt