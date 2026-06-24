module top (
    input       clk,
    input       rst,
    input       uart_rxd,
    output wire [3:0] led
);

wire [7:0] rx_data;
wire rx_done;

uart_rx u_uart_rx (
    .clk          (clk),
    .rst          (rst),
    .uart_rxd     (uart_rxd),
    .uart_rx_data (rx_data),
    .uart_rx_done (rx_done)
);

reg en_shift;       // 1:运行, 0:暂停
reg mode;           // 0:跑马灯, 1:流水灯

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        en_shift <= 1'b0;
        mode     <= 1'b0;
    end else if (rx_done) begin
        case (rx_data)
            8'h01: en_shift <= 1'b1;
            8'h02: en_shift <= 1'b0;
            8'h03: mode <= ~mode;
            default: ;
        endcase
    end
end

// 1Hz移位脉冲产生器 (50MHz)
localparam CLK_FREQ = 50_000_000;
localparam ONE_SEC_CNT = CLK_FREQ - 1;

reg [25:0] cnt;
reg shift_pulse;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        cnt <= 0;
        shift_pulse <= 0;
    end else begin
        if (cnt == ONE_SEC_CNT) begin
            cnt <= 0;
            shift_pulse <= 1'b1;
        end else begin
            cnt <= cnt + 1;
            shift_pulse <= 1'b0;
        end
    end
end

// LED状态机
reg [3:0] led_state;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        led_state <= 4'b0001;    // 复位后从0001开始
    end else if (en_shift && shift_pulse) begin
        if (mode == 0) begin
            // 跑马灯模式：单灯循环左移
            led_state <= {led_state[2:0], led_state[3]};
        end else begin
            // 流水灯模式：按用户要求序列循环
            case (led_state)
                4'b0001: led_state <= 4'b0011;
                4'b0011: led_state <= 4'b0111;
                4'b0111: led_state <= 4'b1111;
                4'b1111: led_state <= 4'b1110;
                4'b1110: led_state <= 4'b1100;
                4'b1100: led_state <= 4'b1000;
                4'b1000: led_state <= 4'b0000;
                4'b0000: led_state <= 4'b0001;
                default:  led_state <= 4'b0001;   // 防错
            endcase
        end
    end
    // 暂停时保持状态
end

assign led = led_state;

endmodule