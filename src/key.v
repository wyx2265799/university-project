module key (
    input           clk             ,   //时钟
    input           rst             ,   //复位,低电平有效
    input           key_in          ,   //待消抖的按键信号
    output  reg     key_out             //已消抖的按键信号     
);
parameter           TIME = 999_999  ;   //20ms时间参数
reg     [19:0]      cnt             ;   //20ms时间计数器
reg     [1:0]       k_in            ;   //同步打拍,消除亚稳态
//同步打拍,消除亚稳态
always @(posedge clk or negedge rst)
    if(rst == 0)
        k_in <= 1;
    else
        k_in <= {k_in[0],key_in};
//20ms时间计数器
always @(posedge clk or negedge rst)
    if(rst == 0)
        cnt <= 0;
    else if(k_in[1] == 1)
        cnt <= 0;
    else if(k_in[1] == 0 && cnt == TIME)
        cnt <= cnt;
    else
        cnt <= cnt + 1;
//输出
always @(posedge clk or negedge rst)
    if(rst == 0)
        key_out <= 0;
    else if(cnt == TIME >> 1)
        key_out <= 1;
    else
        key_out <= 0;
endmodule