module uart_rx_byte #(
    parameter UART_BPS = 9600,
    parameter CLK_FREQ = 50_000_000
)(
    input       clk,
    input       rst_n,
    input       uart_rxd,
    output reg [7:0] data,
    output reg       data_valid
);

localparam BAUD_CNT_MAX = (CLK_FREQ / UART_BPS) - 1;

reg [2:0]  rx_sync;
reg        work_en;
reg [15:0] baud_cnt;
reg [3:0]  bit_cnt;
reg [7:0]  rx_shift;

wire start_edge = rx_sync[2] & ~rx_sync[1];
wire sample_en  = (baud_cnt == (BAUD_CNT_MAX >> 1));

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        rx_sync <= 3'b111;
    else
        rx_sync <= {rx_sync[1:0], uart_rxd};
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        work_en <= 1'b0;
    else if (start_edge)
        work_en <= 1'b1;
    else if (sample_en && bit_cnt == 4'd9)
        work_en <= 1'b0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        baud_cnt <= 16'd0;
    else if (!work_en || baud_cnt >= BAUD_CNT_MAX)
        baud_cnt <= 16'd0;
    else
        baud_cnt <= baud_cnt + 16'd1;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        bit_cnt <= 4'd0;
    else if (!work_en)
        bit_cnt <= 4'd0;
    else if (sample_en)
        bit_cnt <= bit_cnt + 4'd1;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        rx_shift <= 8'd0;
    else if (sample_en && bit_cnt >= 4'd1 && bit_cnt <= 4'd8)
        rx_shift <= {rx_sync[1], rx_shift[7:1]};
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data       <= 8'd0;
        data_valid <= 1'b0;
    end else if (sample_en && bit_cnt == 4'd9) begin
        data       <= rx_shift;
        data_valid <= 1'b1;
    end else begin
        data_valid <= 1'b0;
    end
end

endmodule
