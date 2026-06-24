transcript file modelsim_tetris_transcript.txt
if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vlog ../class_design/key_debounce.v
vlog ../class_design/seven_seg_score.v
vlog ../class_design/uart_rx_byte.v
vlog ../class_design/uart_tx_byte.v
vlog ../class_design/tetris_music.v
vlog ../class_design/ws2812_matrix.v
vlog ../class_design/tetris_core.v
vlog ../class_design/tetris_top.v
vlog tb_tetris_top.v
vsim -wlf tetris_top_sim.wlf work.tb_tetris_top
log /tb_tetris_top/clk
log /tb_tetris_top/key5
log /tb_tetris_top/uart_rxd
log /tb_tetris_top/uart_txd
log /tb_tetris_top/dut/rst_n
log /tb_tetris_top/dut/difficulty
log /tb_tetris_top/dut/game_state
log /tb_tetris_top/dut/score_bcd
log /tb_tetris_top/dut/score_report_pending
log /tb_tetris_top/dut/tx_active
log /tb_tetris_top/dut/tx_idx
log /tb_tetris_top/dut/tx_data
log /tb_tetris_top/dut/rx_data
log /tb_tetris_top/dut/rx_valid
log /tb_tetris_top/dut/key_pulse
run 120 ms
quit -f
