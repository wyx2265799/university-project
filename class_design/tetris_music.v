module music(
    input  wire clk,
    input  wire rst_n,
    output reg  buzzer
);

localparam [25:0] EIGHTH_CNT  = 26'd12_500_000;
localparam [25:0] QUARTER_CNT = 26'd25_000_000;
localparam [5:0]  LAST_NOTE   = 6'd39;

reg [25:0] beat_cnt;
reg [25:0] duration;
reg [15:0] half_prd;
reg [15:0] pwm_cnt;
reg [5:0]  ptr;

wire [8:0] melody_data = melody_a(ptr);
wire [4:0] current_note = melody_data[8:4];
wire [3:0] current_beat = melody_data[3:0];

function [8:0] melody_a;
    input [5:0] idx;
    begin
        case (idx)
            6'd0:  melody_a = {5'd3,  4'd2};
            6'd1:  melody_a = {5'd14, 4'd1};
            6'd2:  melody_a = {5'd1,  4'd1};
            6'd3:  melody_a = {5'd2,  4'd2};
            6'd4:  melody_a = {5'd1,  4'd1};
            6'd5:  melody_a = {5'd14, 4'd1};
            6'd6:  melody_a = {5'd13, 4'd2};
            6'd7:  melody_a = {5'd13, 4'd1};
            6'd8:  melody_a = {5'd1,  4'd1};
            6'd9:  melody_a = {5'd3,  4'd2};
            6'd10: melody_a = {5'd2,  4'd1};
            6'd11: melody_a = {5'd1,  4'd1};
            6'd12: melody_a = {5'd14, 4'd2};
            6'd13: melody_a = {5'd14, 4'd1};
            6'd14: melody_a = {5'd1,  4'd1};
            6'd15: melody_a = {5'd2,  4'd2};
            6'd16: melody_a = {5'd3,  4'd2};
            6'd17: melody_a = {5'd1,  4'd2};
            6'd18: melody_a = {5'd13, 4'd2};
            6'd19: melody_a = {5'd13, 4'd4};
            6'd20: melody_a = {5'd2,  4'd2};
            6'd21: melody_a = {5'd2,  4'd1};
            6'd22: melody_a = {5'd4,  4'd1};
            6'd23: melody_a = {5'd6,  4'd2};
            6'd24: melody_a = {5'd5,  4'd1};
            6'd25: melody_a = {5'd4,  4'd1};
            6'd26: melody_a = {5'd3,  4'd2};
            6'd27: melody_a = {5'd3,  4'd1};
            6'd28: melody_a = {5'd1,  4'd1};
            6'd29: melody_a = {5'd3,  4'd2};
            6'd30: melody_a = {5'd2,  4'd1};
            6'd31: melody_a = {5'd1,  4'd1};
            6'd32: melody_a = {5'd14, 4'd2};
            6'd33: melody_a = {5'd14, 4'd1};
            6'd34: melody_a = {5'd1,  4'd1};
            6'd35: melody_a = {5'd2,  4'd2};
            6'd36: melody_a = {5'd3,  4'd2};
            6'd37: melody_a = {5'd1,  4'd2};
            6'd38: melody_a = {5'd13, 4'd2};
            6'd39: melody_a = {5'd13, 4'd4};
            default: melody_a = {5'd0, 4'd1};
        endcase
    end
endfunction

function [15:0] half_period;
    input [4:0] note;
    begin
        case (note)
            5'd1:  half_period = 16'd47785;
            5'd2:  half_period = 16'd42580;
            5'd3:  half_period = 16'd37924;
            5'd4:  half_period = 16'd35800;
            5'd5:  half_period = 16'd31888;
            5'd6:  half_period = 16'd28409;
            5'd7:  half_period = 16'd25050;
            5'd13: half_period = 16'd56818;
            5'd14: half_period = 16'd50100;
            5'd15: half_period = 16'd23898;
            default: half_period = 16'd0;
        endcase
    end
endfunction

function [25:0] beat_duration;
    input [3:0] beat;
    begin
        case (beat)
            4'd1: beat_duration = EIGHTH_CNT;
            4'd2: beat_duration = QUARTER_CNT;
            4'd3: beat_duration = QUARTER_CNT + EIGHTH_CNT;
            4'd4: beat_duration = QUARTER_CNT + QUARTER_CNT;
            default: beat_duration = EIGHTH_CNT;
        endcase
    end
endfunction

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        beat_cnt <= 26'd0;
        duration <= 26'd0;
        half_prd <= 16'd0;
        pwm_cnt  <= 16'd0;
        ptr      <= 6'd0;
        buzzer   <= 1'b0;
    end else begin
        if (beat_cnt >= duration) begin
            beat_cnt <= 26'd0;
            duration <= beat_duration(current_beat);
            half_prd <= half_period(current_note);
            if (ptr == LAST_NOTE)
                ptr <= 6'd0;
            else
                ptr <= ptr + 6'd1;
        end else begin
            beat_cnt <= beat_cnt + 26'd1;
        end

        if (half_prd == 16'd0) begin
            buzzer  <= 1'b0;
            pwm_cnt <= 16'd0;
        end else if (pwm_cnt >= half_prd - 16'd1) begin
            pwm_cnt <= 16'd0;
            buzzer  <= ~buzzer;
        end else begin
            pwm_cnt <= pwm_cnt + 16'd1;
        end
    end
end

endmodule
