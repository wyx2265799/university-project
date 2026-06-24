module ws2812_matrix #(
    parameter LED_COUNT = 64,
    parameter BIT_CYCLES = 64,
    parameter T0H_CYCLES = 18,
    parameter T1H_CYCLES = 32,
    parameter RESET_CYCLES = 15000
)(
    input                       clk,
    input                       rst_n,
    output reg [5:0]            pixel_index,
    input      [23:0]           pixel_rgb,
    output reg                  dq
);

localparam S_RESET = 2'd0;
localparam S_LOAD  = 2'd1;
localparam S_SEND  = 2'd2;

reg [1:0]  state;
reg [5:0]  bit_cycle;
reg [4:0]  bit_idx;
reg [6:0]  led_idx;
reg [13:0] reset_cnt;
reg [23:0] grb_data;

wire        current_bit = grb_data[23 - bit_idx];
wire [5:0]  high_cycles = current_bit ? T1H_CYCLES[5:0] : T0H_CYCLES[5:0];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bit_cycle <= 6'd0;
        bit_idx   <= 5'd0;
        led_idx   <= 7'd0;
        reset_cnt <= 14'd0;
        state     <= S_RESET;
        pixel_index <= 6'd0;
        grb_data  <= 24'd0;
        dq        <= 1'b0;
    end else begin
        case (state)
            S_RESET: begin
                dq <= 1'b0;
                if (reset_cnt >= RESET_CYCLES - 1) begin
                    reset_cnt   <= 14'd0;
                    led_idx     <= 7'd0;
                    pixel_index <= 6'd0;
                    state       <= S_LOAD;
                end else begin
                    reset_cnt <= reset_cnt + 14'd1;
                end
            end

            S_LOAD: begin
                dq        <= 1'b0;
                grb_data  <= {pixel_rgb[15:8], pixel_rgb[23:16], pixel_rgb[7:0]};
                bit_cycle <= 6'd0;
                bit_idx   <= 5'd0;
                state     <= S_SEND;
            end

            S_SEND: begin
                dq <= (bit_cycle < high_cycles);
                if (bit_cycle >= BIT_CYCLES - 1) begin
                    bit_cycle <= 6'd0;
                    if (bit_idx == 5'd23) begin
                        bit_idx <= 5'd0;
                        if (led_idx == LED_COUNT - 1) begin
                            led_idx     <= 7'd0;
                            pixel_index <= 6'd0;
                            state       <= S_RESET;
                        end else begin
                            led_idx     <= led_idx + 7'd1;
                            pixel_index <= led_idx[5:0] + 6'd1;
                            state       <= S_LOAD;
                        end
                    end else begin
                        bit_idx <= bit_idx + 5'd1;
                    end
                end else begin
                    bit_cycle <= bit_cycle + 6'd1;
                end
            end

            default: state <= S_RESET;
        endcase
    end
end

endmodule
