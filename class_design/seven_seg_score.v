module seven_seg_score #(
    parameter CLK_FREQ = 50_000_000
)(
    input        clk,
    input        rst_n,
    input  [2:0] difficulty,
    input [19:0] score_bcd,
    input        blink_score,
    output reg [5:0] sel,
    output reg [7:0] seg
);

localparam SCAN_DIV  = CLK_FREQ / 6000;
localparam BLINK_DIV = CLK_FREQ / 2;

reg [15:0] scan_cnt;
reg [2:0]  scan_idx;
reg [25:0] blink_cnt;
reg        blink_phase;

wire [3:0] s4 = score_bcd[19:16];
wire [3:0] s3 = score_bcd[15:12];
wire [3:0] s2 = score_bcd[11:8];
wire [3:0] s1 = score_bcd[7:4];
wire [3:0] s0 = score_bcd[3:0];

reg [3:0] digit;
reg       blank_digit;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        scan_cnt <= 16'd0;
        scan_idx <= 3'd0;
    end else if (scan_cnt >= SCAN_DIV - 1) begin
        scan_cnt <= 16'd0;
        if (scan_idx == 3'd5)
            scan_idx <= 3'd0;
        else
            scan_idx <= scan_idx + 3'd1;
    end else begin
        scan_cnt <= scan_cnt + 16'd1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        blink_cnt   <= 26'd0;
        blink_phase <= 1'b0;
    end else if (blink_cnt >= BLINK_DIV - 1) begin
        blink_cnt   <= 26'd0;
        blink_phase <= ~blink_phase;
    end else begin
        blink_cnt <= blink_cnt + 26'd1;
    end
end

always @(*) begin
    blank_digit = 1'b0;
    case (scan_idx)
        3'd0: digit = {1'b0, difficulty};
        3'd1: digit = s4;
        3'd2: digit = s3;
        3'd3: digit = s2;
        3'd4: digit = s1;
        3'd5: digit = s0;
        default: digit = 4'd0;
    endcase

    if (blink_score && blink_phase && scan_idx != 3'd0)
        blank_digit = 1'b1;
end

always @(*) begin
    sel = ~(6'b000001 << scan_idx);
    if (blank_digit) begin
        seg = 8'b1111_1111;
    end else begin
        case (digit)
            4'd0: seg = 8'b0100_0000;
            4'd1: seg = 8'b0111_1001;
            4'd2: seg = 8'b0010_0100;
            4'd3: seg = 8'b0011_0000;
            4'd4: seg = 8'b0001_1001;
            4'd5: seg = 8'b0001_0010;
            4'd6: seg = 8'b0000_0010;
            4'd7: seg = 8'b0111_1000;
            4'd8: seg = 8'b0000_0000;
            4'd9: seg = 8'b0001_0000;
            default: seg = 8'b1111_1111;
        endcase
    end
end

endmodule
