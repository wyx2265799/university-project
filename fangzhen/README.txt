ModelSim 仿真说明
=================

本目录存放俄罗斯方块项目的仿真文件，不参与 FPGA 烧录综合。

目录关系：
- ../class_design  存放工程 Verilog 源码
- ./tb_tetris_top.v  顶层仿真 testbench
- ./run_tetris_wave.do  命令行仿真脚本，生成 tetris_top_sim.wlf
- ./capture_tetris_uart_wave.do  打开 UART 难度输入与分数回传波形，便于截图
- ./capture_tetris_key_wave.do  打开 KEY5 开始/暂停状态机波形，便于截图

命令行仿真：
1. 打开 ModelSim 或命令行，当前目录切换到本 fangzhen 目录。
2. 执行：
   vsim -c -do run_tetris_wave.do
3. 看到 Errors: 0, Warnings: 0 即表示仿真通过。

截图波形：
1. 打开 ModelSim，当前目录切换到本 fangzhen 目录。
2. UART 波形执行：
   do capture_tetris_uart_wave.do
   脚本会缩放到 2ms 到 16ms。
3. KEY5 状态机波形执行：
   do capture_tetris_key_wave.do
   脚本会缩放到 30ms 到 112ms。
4. 在 ModelSim Wave 窗口中截图后插入 Word 报告。
