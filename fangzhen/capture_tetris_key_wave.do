transcript file modelsim_tetris_key_capture_transcript.txt
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
vsim -wlf tetris_top_key_capture.wlf work.tb_tetris_top
view wave
add wave -divider "KEY5 Start Pause State Machine"
add wave -radix binary /tb_tetris_top/clk
add wave -radix binary /tb_tetris_top/key5
add wave -radix unsigned /tb_tetris_top/dut/rst_n
add wave -radix binary /tb_tetris_top/dut/key_pulse
add wave -radix unsigned /tb_tetris_top/dut/game_state
add wave -radix unsigned /tb_tetris_top/dut/difficulty
add wave -radix hexadecimal /tb_tetris_top/dut/score_bcd
add wave -radix binary /tb_tetris_top/dut/tx_active
add wave -radix unsigned /tb_tetris_top/dut/tx_idx
add wave -radix binary /tb_tetris_top/buzzer
run 120 ms
WaveRestoreZoom {30ms} {112ms}
