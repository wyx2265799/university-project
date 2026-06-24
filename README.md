# AWC_C4 FPGA Tetris

FPGA Russian Tetris project for the AWC_C4 DVK board, implemented in Verilog HDL on `Intel Cyclone IV E EP4CE6F17C8N`.

## Structure

- `class_design/`: main design source files
- `fangzhen/`: ModelSim testbench and simulation scripts
- `p/`: Quartus project files
- `AWC_C4_DVK_俄罗斯方块_FPGA项目报告_提交版.docx`: project report

## Features

- 8x8 WS2812 RGB matrix game display
- 6-digit seven-segment score display
- 5-key game control
- UART difficulty setup and score reporting
- Buzzer background music

## Simulation

ModelSim simulation files are under `fangzhen/`.

- `run_tetris_wave.do`
- `capture_tetris_uart_wave.do`
- `capture_tetris_key_wave.do`

## Build

Open the Quartus project:

- `p/key.qpf`
