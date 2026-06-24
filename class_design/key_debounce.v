module key_debounce #(
    parameter KEY_WIDTH = 5,
    parameter DEBOUNCE_TIME = 1_000_000
)(
    input                       clk,
    input                       rst_n,
    input      [KEY_WIDTH-1:0]  key_n,
    output     [KEY_WIDTH-1:0]  press_pulse
);

reg [KEY_WIDTH-1:0] key_sync0;
reg [KEY_WIDTH-1:0] key_sync1;
reg [KEY_WIDTH-1:0] key_state;
reg [KEY_WIDTH-1:0] press_reg;
reg [20:0] cnt;
wire sample_tick = (cnt >= DEBOUNCE_TIME - 1);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        key_sync0 <= {KEY_WIDTH{1'b1}};
        key_sync1 <= {KEY_WIDTH{1'b1}};
    end else begin
        key_sync0 <= key_n;
        key_sync1 <= key_sync0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt <= 21'd0;
    else if (sample_tick)
        cnt <= 21'd0;
    else
        cnt <= cnt + 21'd1;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        key_state   <= {KEY_WIDTH{1'b1}};
        press_reg   <= {KEY_WIDTH{1'b0}};
    end else if (sample_tick) begin
        press_reg   <= key_state & ~key_sync1;
        key_state   <= key_sync1;
    end else begin
        press_reg <= {KEY_WIDTH{1'b0}};
    end
end

assign press_pulse = press_reg;

endmodule
