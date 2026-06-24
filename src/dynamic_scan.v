module dynamic_scan (
    input           clk,
    input           rst,
    input           inc_pulse,      // 按键1：点亮时间 +50ms
    input           dec_pulse,      // 按键2：点亮时间 -50ms
    output reg [5:0] sel,           // 位选（低有效）
    output reg [7:0] seg            // 段选（共阳极）
);

parameter TIME_1MS  = 49_999;       // 1ms 计数值 (50MHz)
parameter STEP_50MS = 2_500_000;    // 50ms 的时钟周期数

reg [24:0] time_scan;               // 当前一位点亮时间（计数终值）
reg [24:0] scan_cnt;                // 扫描计时器
wire       scan_end;                // 计满一个点亮周期

reg [2:0]  digit_sel;               // 当前点亮的位编号 0~5
reg [3:0]  digit_val;               // 当前位要显示的数字
reg [3:0]  level;                   // 刷新率档位 0~9

// 固定显示数字：左5位显示 1,2,3,4,5
wire [3:0] fixed_digits [0:4];
assign fixed_digits[0] = 4'd1;
assign fixed_digits[1] = 4'd2;
assign fixed_digits[2] = 4'd3;
assign fixed_digits[3] = 4'd4;
assign fixed_digits[4] = 4'd5;

// -----------------------------------------------------------------
// 1. 档位与点亮时间控制（带边界保护）
// -----------------------------------------------------------------
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        level     <= 0;
        time_scan <= TIME_1MS;
    end else begin
        if (inc_pulse) begin
            if (level < 9) begin
                level     <= level + 1;
                time_scan <= time_scan + STEP_50MS;
            end
        end else if (dec_pulse) begin
            if (level > 0) begin
                level     <= level - 1;
                time_scan <= time_scan - STEP_50MS;
            end
        end
    end
end

// -----------------------------------------------------------------
// 2. 扫描计时器（按键时强制清零，防止卡死）
// -----------------------------------------------------------------
always @(posedge clk or negedge rst) begin
    if (!rst)
        scan_cnt <= 0;
    else if (inc_pulse || dec_pulse || scan_end)
        scan_cnt <= 0;
    else
        scan_cnt <= scan_cnt + 1;
end
assign scan_end = (scan_cnt == time_scan);

// -----------------------------------------------------------------
// 3. 位选计数器（按键时回到0号位）
// -----------------------------------------------------------------
always @(posedge clk or negedge rst) begin
    if (!rst)
        digit_sel <= 0;
    else if (inc_pulse || dec_pulse)
        digit_sel <= 0;
    else if (scan_end)
        digit_sel <= (digit_sel == 5) ? 0 : digit_sel + 1;
end

// -----------------------------------------------------------------
// 4. 当前位对应的数字：右1位显示档位，其余显示固定数字
// -----------------------------------------------------------------
always @(*) begin
    if (digit_sel == 5)
        digit_val = level;
    else
        digit_val = fixed_digits[digit_sel];
end

// -----------------------------------------------------------------
// 5. 位选输出（低电平有效，独热码）
// -----------------------------------------------------------------
always @(posedge clk or negedge rst) begin
    if (!rst)
        sel <= 6'b111_111;          // 全灭
    else
        case (digit_sel)
            0: sel <= 6'b111_110;
            1: sel <= 6'b111_101;
            2: sel <= 6'b111_011;
            3: sel <= 6'b110_111;
            4: sel <= 6'b101_111;
            5: sel <= 6'b011_111;
            default: sel <= 6'b111_111;
        endcase
end

// -----------------------------------------------------------------
// 6. 段选输出（共阳极段码表）
// -----------------------------------------------------------------
always @(posedge clk or negedge rst) begin
    if (!rst)
        seg <= 8'b1111_1111;
    else
        case (digit_val)
            0: seg <= 8'b0100_0000;
            1: seg <= 8'b0111_1001;
            2: seg <= 8'b0010_0100;
            3: seg <= 8'b0011_0000;
            4: seg <= 8'b0001_1001;
            5: seg <= 8'b0001_0010;
            6: seg <= 8'b0000_0010;
            7: seg <= 8'b0111_1000;
            8: seg <= 8'b0000_0000;
            9: seg <= 8'b0001_0000;
            default: seg <= 8'b1111_1111;
        endcase
end

endmodule