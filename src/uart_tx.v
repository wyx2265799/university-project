module uart_tx #(
    parameter   UART_BPS    =   9600        ,
                CLK_FREQ    =   50_000_000
)(
    input                   clk             ,
    input                   rst             ,
    input                   uart_tx_en      ,   //串口接收模块输出的数据接收完成标志
    input   [7:0]           uart_tx_data    ,   //串口接收模块输出八位数据给到串口接收模块
    output reg              uart_txd            //串口发送数据        
);
localparam  BAUD_CNT_MAX    =   (CLK_FREQ/UART_BPS) - 1;
reg     [12:0]      baud_cnt    ;   //波特率计数器
reg                 bit_flag    ;   //比特标志信号
reg     [3:0]       bit_cnt     ;   //比特计数器
reg                 work_en     ;   //工作使能信号
//工作使能信号
always @(posedge clk or negedge rst) 
    if(rst == 0)
        work_en <= 0;
    else if(uart_tx_en)
        work_en <= 1;
    else if((bit_cnt == 9) && bit_flag)
        work_en <= 0;
//波特率计数器
always @(posedge clk or negedge rst) 
    if(rst == 0)
        baud_cnt <= 0;
    else if((baud_cnt == BAUD_CNT_MAX) || !work_en)
        baud_cnt <= 0;
    else if(work_en)
        baud_cnt <= baud_cnt + 1;
//比特标志信号
always @(posedge clk or negedge rst) 
    if(rst == 0)
        bit_flag <= 0;
    else if(baud_cnt == BAUD_CNT_MAX >> 1)
        bit_flag <= 1;
    else
        bit_flag <= 0;
//比特计数器
always @(posedge clk or negedge rst) 
    if(rst == 0)
        bit_cnt <= 0;
    else if((bit_cnt == 9) && bit_flag)
        bit_cnt <= 0;
    else if(bit_flag)
        bit_cnt <= bit_cnt + 1;
//串口发送数据  
always @(posedge clk or negedge rst) 
    if(rst == 0)
        uart_txd <= 1;
    else if(bit_flag)
        case (bit_cnt)
            0:uart_txd <= 0;                //起始位
            1:uart_txd <= uart_tx_data[0];  //数据位低位
            2:uart_txd <= uart_tx_data[1];
            3:uart_txd <= uart_tx_data[2];
            4:uart_txd <= uart_tx_data[3];
            5:uart_txd <= uart_tx_data[4];
            6:uart_txd <= uart_tx_data[5];
            7:uart_txd <= uart_tx_data[6];
            8:uart_txd <= uart_tx_data[7];  //数据位高位
            9:uart_txd <= 1;                //停止位
            default:uart_txd <= 1;
        endcase
endmodule