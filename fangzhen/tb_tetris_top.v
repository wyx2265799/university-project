`timescale 1ns/1ps

module tb_tetris_top;

reg clk;
reg key1;
reg key2;
reg key3;
reg key4;
reg key5;
reg uart_rxd;
wire uart_txd;
wire dq;
wire [5:0] sel;
wire [7:0] seg;
wire buzzer;

localparam integer CLK_HALF_NS = 10;
localparam integer UART_BIT_NS = 104167;

tetris_top dut (
    .clk      (clk),
    .key1     (key1),
    .key2     (key2),
    .key3     (key3),
    .key4     (key4),
    .key5     (key5),
    .uart_rxd (uart_rxd),
    .uart_txd (uart_txd),
    .dq       (dq),
    .sel      (sel),
    .seg      (seg),
    .buzzer   (buzzer)
);

initial begin
    clk = 1'b0;
    forever #CLK_HALF_NS clk = ~clk;
end

task uart_send_byte;
    input [7:0] data;
    integer i;
    begin
        uart_rxd = 1'b1;
        #(UART_BIT_NS);
        uart_rxd = 1'b0;
        #(UART_BIT_NS);
        for (i = 0; i < 8; i = i + 1) begin
            uart_rxd = data[i];
            #(UART_BIT_NS);
        end
        uart_rxd = 1'b1;
        #(UART_BIT_NS);
    end
endtask

task press_key5;
    begin
        key5 = 1'b0;
        #25_000_000;
        key5 = 1'b1;
        #25_000_000;
    end
endtask

initial begin
    key1 = 1'b1;
    key2 = 1'b1;
    key3 = 1'b1;
    key4 = 1'b1;
    key5 = 1'b1;
    uart_rxd = 1'b1;

    #3_000_000;
    uart_send_byte(8'h31);
    #5_000_000;

    press_key5();
    #5_000_000;
    press_key5();
    #5_000_000;

    $finish;
end

endmodule
