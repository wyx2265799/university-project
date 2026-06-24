`timescale 1ns/1ns       //时间单位/时间精度
//内部信号定义
module test ();

reg clk;
reg rst;
wire [3:0] led;
//定义时间50MHZ
always #10 clk=~clk;
//重定义源代码时间参数
parameter TIME_4s    = 1999;
parameter TIME_500ms = 249;
//产生刺激信号激活源代码
initial begin
    clk = 0;
    rst = 0;
    #20 //delay 20ms
    rst = 1;
    #200000
    $stop;
end
//例化源代码
state_led #(
    .TIME_4s (TIME_4s),
    .TIME_500ms (TIME_500ms)
)state_led_inst(
    .clk    (clk),
    .rst    (rst),
    .led    (led)
);
endmodule