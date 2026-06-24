module uart_top (
    input               clk         ,
    input               rst         ,
    input               uart_rxd    ,   //接收数据
    output              uart_txd        //发送数据 
);
wire    [7:0]   uart_rx_data;
wire            uart_rx_done;
uart_rx uart_rx_inst(
    /* input                */.clk          (clk            ),
    /* input                */.rst          (rst            ),
    /* input                */.uart_rxd     (uart_rxd       ),   //接收数据
    /* output  reg [7:0]    */.uart_rx_data (uart_rx_data   ),   //输出串转并的数据
    /* output  reg          */.uart_rx_done (uart_rx_done   )    //串口接收数据完成标志
);
uart_tx uart_tx_inst(
    /* input                */.clk          (clk            ),
    /* input                */.rst          (rst            ),
    /* input                */.uart_tx_en   (uart_rx_done   ),   //串口接收模块输出的数据接收完成标志
    /* input   [7:0]        */.uart_tx_data (uart_rx_data   ),   //串口接收模块输出八位数据给到串口接收模块
    /* output reg           */.uart_txd     (uart_txd       )    //串口发送数据        
);
endmodule