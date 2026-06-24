transcript file modelsim_tetris_uart_capture_transcript.txt
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
vsim -wlf tetris_top_uart_capture.wlf work.tb_tetris_top
view wave
add wave -divider "UART Difficulty Input and Score TX"
add wave -radix binary /tb_tetris_top/clk
add wave -radix binary /tb_tetris_top/uart_rxd
add wave -radix binary /tb_tetris_top/uart_txd
add wave -radix unsigned /tb_tetris_top/dut/rst_n
add wave -radix unsigned /tb_tetris_top/dut/difficulty
add wave -radix hexadecimal /tb_tetris_top/dut/rx_data
add wave -radix binary /tb_tetris_top/dut/rx_valid
add wave -radix hexadecimal /tb_tetris_top/dut/score_bcd
add wave -radix binary /tb_tetris_top/dut/score_report_pending
add wave -radix binary /tb_tetris_top/dut/tx_active
add wave -radix unsigned /tb_tetris_top/dut/tx_idx
add wave -radix hexadecimal /tb_tetris_top/dut/tx_data
run 120 ms
WaveRestoreZoom {2ms} {16ms}
