module uart_tx_byte #(
    parameter UART_BPS = 9600,
    parameter CLK_FREQ = 50_000_000
)(
    input       clk,
    input       rst_n,
    input       tx_start,
    input [7:0] tx_data,
    output reg  uart_txd,
    output reg  tx_busy,
    output reg  tx_done
);

localparam BAUD_CNT_MAX = (CLK_FREQ / UART_BPS) - 1;

reg [15:0] baud_cnt;
reg [3:0]  bit_cnt;
reg [7:0]  data_latch;

wire bit_done = (baud_cnt >= BAUD_CNT_MAX);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_busy    <= 1'b0;
        baud_cnt   <= 16'd0;
        bit_cnt    <= 4'd0;
        data_latch <= 8'd0;
        tx_done    <= 1'b0;
    end else if (tx_start && !tx_busy) begin
        tx_busy    <= 1'b1;
        baud_cnt   <= 16'd0;
        bit_cnt    <= 4'd0;
        data_latch <= tx_data;
        tx_done    <= 1'b0;
    end else if (tx_busy) begin
        if (bit_done) begin
            baud_cnt <= 16'd0;
            if (bit_cnt == 4'd9) begin
                tx_busy <= 1'b0;
                bit_cnt <= 4'd0;
                tx_done <= 1'b1;
            end else begin
                bit_cnt <= bit_cnt + 4'd1;
                tx_done <= 1'b0;
            end
        end else begin
            baud_cnt <= baud_cnt + 16'd1;
            tx_done  <= 1'b0;
        end
    end else begin
        tx_done <= 1'b0;
    end
end

always @(*) begin
    if (!tx_busy)
        uart_txd = 1'b1;
    else begin
        case (bit_cnt)
            4'd0: uart_txd = 1'b0;
            4'd1: uart_txd = data_latch[0];
            4'd2: uart_txd = data_latch[1];
            4'd3: uart_txd = data_latch[2];
            4'd4: uart_txd = data_latch[3];
            4'd5: uart_txd = data_latch[4];
            4'd6: uart_txd = data_latch[5];
            4'd7: uart_txd = data_latch[6];
            4'd8: uart_txd = data_latch[7];
            4'd9: uart_txd = 1'b1;
            default: uart_txd = 1'b1;
        endcase
    end
end

endmodule
