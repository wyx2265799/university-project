module uart_rx (
    input       clk,
    input       rst,
    input       uart_rxd,//接收数据
    output reg [7:0] uart_rx_data,
    output reg  uart_rx_done //接收完成标志
);
parameter UART_BPS = 9600,  
          CLK_FREQ = 50_000_000,
          BAUD_CNT_MAX = (CLK_FREQ/UART_BPS) - 1;
reg [2:0] rx_reg ;//同步打拍，消除亚稳态
wire start_nedge;//检测起始位下降沿
reg     work_en;//工作使能信号
reg [15:0] baud_cnt;//波特率计数器
reg     bit_flag;//什么时候接收信号
reg  [7:0] bit_cnt;//比特计数器
reg [7:0] rx_data;//串-》bing data
reg rx_flag;
always @(posedge clk or negedge rst) begin
    if(!rst)
        rx_reg<=1;
    else
        rx_reg <= {rx_reg[1],rx_reg[0],uart_rxd};

end
//检测起始位下降沿
assign start_nedge = ~rx_reg[1] & rx_reg [2];
//工作使能信号
always @(posedge clk or negedge rst) begin
    if(!rst)
        work_en<=0;
    else if(start_nedge)
        work_en <=1;
    else if(bit_cnt == 8 && bit_flag)
        work_en <= 0;
end
//波特率计数器
always @(posedge clk or negedge rst) begin
    if(!rst)
        baud_cnt <=0;
    else if(baud_cnt == BAUD_CNT_MAX || work_en == 0)
        baud_cnt<=0;
    else if(work_en)
        baud_cnt<=baud_cnt+1;
end
//比特标志信号
always @(posedge clk or negedge rst) begin
    if(!rst)
        bit_flag<=0;
    else if(baud_cnt == BAUD_CNT_MAX>>1)
        bit_flag<=1;
    else    
        bit_flag<=0;
end
//比特计数器
always @(posedge clk or negedge rst) begin
    if(!rst)
        bit_cnt<=0;
    else if(bit_cnt == 8 && bit_flag)
        bit_cnt<=0;
    else if(bit_flag)
        bit_cnt <=bit_cnt +1;
end
//串行数据转并行数据
always @(posedge clk or negedge rst) begin
    if(!rst)
        rx_data<=0;
    else if((bit_cnt >=1 && bit_cnt <= 8) && bit_flag)
        rx_data<={rx_reg[1],rx_data[7:1]};
end
//寄存串口接受数据完成标志
always @(posedge clk or negedge rst) begin
    if(!rst)
        rx_flag <=0;
    else if(bit_cnt == 8 && bit_flag)
        rx_flag<=1;
    else
        rx_flag<=0;
end
//输出串转并的数据
always @(posedge clk or negedge rst)
    if(rst == 0)
        uart_rx_data <= 0;
    else if(rx_flag)
        uart_rx_data <= rx_data;
//串口接收数据完成标志
always @(posedge clk or negedge rst)
    if(rst == 0)
        uart_rx_done <= 0;
    else
        uart_rx_done <= rx_flag;
endmodule