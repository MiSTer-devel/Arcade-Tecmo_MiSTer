create_generated_clock -name SDRAM_CLK \
  -source [get_pins -compatibility_mode {emu|pll|pll_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] \
  [get_ports {SDRAM_CLK}]

# data access delay (tAC) plus a small margin to allow for propagation delay
set_input_delay -clock SDRAM_CLK -max [expr 6.0 + 0.5] [get_ports {SDRAM_DQ[*]}]

# data output hold time (tOH)
set_input_delay -clock SDRAM_CLK -min 2.5 [get_ports {SDRAM_DQ[*]}]

# data input setup time (tIS)
set_output_delay -clock SDRAM_CLK -max 1.5 [get_ports {SDRAM_A* SDRAM_BA* SDRAM_D* SDRAM_CKE SDRAM_n*}]

# data input hold time (tIH)
set_output_delay -clock SDRAM_CLK -min -0.8 [get_ports {SDRAM_A* SDRAM_BA* SDRAM_D* SDRAM_CKE SDRAM_n*}]

# use proper edges for the timing calculations
set_multicycle_path -setup -end \
  -rise_from [get_clocks {SDRAM_CLK}] \
  -rise_to [get_clocks {emu|pll|pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] 2
