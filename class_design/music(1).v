// ============================================================
// 文件名: tetris_music.v
// 功能: 在 AWC_C4 DVK (Cyclone IV E) 上播放俄罗斯方块主题曲
//       严格按最新谱面实现：120 BPM，引入低音6(440Hz)与低音7(499Hz)
// 时钟: 50MHz, 蜂鸣器: PIN_J1, 复位: PIN_E15 (KEY1)
// ============================================================

module music(
    input  wire       clk,      // 50MHz
    input  wire       rst_n,    // 低电平复位
    output reg        buzzer    // 蜂鸣器输出
);

// ------------------------------------------------------------
// 节拍参数：120 BPM → 四分音符 = 500 ms
// ------------------------------------------------------------
localparam CLK_FREQ      = 50000000;
localparam BEAT_MS       = 500;              // 四分音符 500 ms
localparam MS_CNT        = CLK_FREQ / 1000;  // 50000
localparam QUARTER_CNT   = BEAT_MS * MS_CNT; // 一拍计数 = 25_000_000
localparam EIGHTH_CNT    = QUARTER_CNT / 2;  // 八分音符时长 = 12_500_000

// 总音符数：A段40 + A段反复40 + B段20 = 100
localparam TOTAL_NOTES   = 100;

// ------------------------------------------------------------
// 半周期计数值查找表（50MHz 时钟, 方波频率 = 50e6/(2*half_period)）
// ------------------------------------------------------------
function [31:0] half_period;
    input [4:0] idx;
    begin
        case (idx)
            0:  half_period = 0;           // 休止
            // 中音 1~7
            1:  half_period = 47785;        // 523 Hz
            2:  half_period = 42580;        // 587 Hz
            3:  half_period = 37924;        // 659 Hz
            4:  half_period = 35800;        // 698 Hz
            5:  half_period = 31888;        // 784 Hz
            6:  half_period = 28409;        // 880 Hz
            7:  half_period = 25050;        // 998 Hz （中音7）
            // 低音 6, 7（比中音低八度）
            13: half_period = 56818;        // 440 Hz （低音6）
            14: half_period = 50100;        // 499 Hz （低音7，按谱面指定）
            // 高音 1
            15: half_period = 23898;        // 1046 Hz
            default: half_period = 0;
        endcase
    end
endfunction

// ------------------------------------------------------------
// 音符与节拍 ROM
// 音符编码：0=休止, 1~7=中音, 13=低音6, 14=低音7, 15=高音1
// 节拍单位：存储八分音符个数
//          2=四分音符(1拍), 1=八分音符(0.5拍), 3=附点四分(1.5拍), 4=二分音符(2拍)
// ------------------------------------------------------------
reg [4:0] note_rom [0:TOTAL_NOTES-1];
reg [3:0] beat_rom [0:TOTAL_NOTES-1];   // 八分音符个数

integer i;
initial begin
    i = 0;

    // ===================== A段（第1-16小节） =====================
    // 小节1: 3(四分) 低7(八分) 1(八分)
    note_rom[i]=3;  beat_rom[i]=2; i=i+1;
    note_rom[i]=14; beat_rom[i]=1; i=i+1;   // 低音7 499Hz
    note_rom[i]=1;  beat_rom[i]=1; i=i+1;
    // 小节2: 2(四分) 1(八分) 低7(八分)
    note_rom[i]=2;  beat_rom[i]=2; i=i+1;
    note_rom[i]=1;  beat_rom[i]=1; i=i+1;
    note_rom[i]=14; beat_rom[i]=1; i=i+1;
    // 小节3: 低6(四分) 低6(八分) 1(八分)
    note_rom[i]=13; beat_rom[i]=2; i=i+1;   // 低音6 440Hz
    note_rom[i]=13; beat_rom[i]=1; i=i+1;
    note_rom[i]=1;  beat_rom[i]=1; i=i+1;
    // 小节4: 3(四分) 2(八分) 1(八分)
    note_rom[i]=3;  beat_rom[i]=2; i=i+1;
    note_rom[i]=2;  beat_rom[i]=1; i=i+1;
    note_rom[i]=1;  beat_rom[i]=1; i=i+1;
    // 小节5: 低7(四分) 低7(八分) 1(八分)
    note_rom[i]=14; beat_rom[i]=2; i=i+1;
    note_rom[i]=14; beat_rom[i]=1; i=i+1;
    note_rom[i]=1;  beat_rom[i]=1; i=i+1;
    // 小节6: 2(四分) 3(四分)
    note_rom[i]=2;  beat_rom[i]=2; i=i+1;
    note_rom[i]=3;  beat_rom[i]=2; i=i+1;
    // 小节7: 1(四分) 低6(四分)
    note_rom[i]=1;  beat_rom[i]=2; i=i+1;
    note_rom[i]=13; beat_rom[i]=2; i=i+1;
    // 小节8: 低6(二分)
    note_rom[i]=13; beat_rom[i]=4; i=i+1;

    // 小节9: 2(四分) 2(八分) 4(八分)
    note_rom[i]=2;  beat_rom[i]=2; i=i+1;
    note_rom[i]=2;  beat_rom[i]=1; i=i+1;
    note_rom[i]=4;  beat_rom[i]=1; i=i+1;
    // 小节10: 6(四分) 5(八分) 4(八分)
    note_rom[i]=6;  beat_rom[i]=2; i=i+1;
    note_rom[i]=5;  beat_rom[i]=1; i=i+1;
    note_rom[i]=4;  beat_rom[i]=1; i=i+1;
    // 小节11: 3(四分) 3(八分) 1(八分)
    note_rom[i]=3;  beat_rom[i]=2; i=i+1;
    note_rom[i]=3;  beat_rom[i]=1; i=i+1;
    note_rom[i]=1;  beat_rom[i]=1; i=i+1;
    // 小节12: 3(四分) 2(八分) 1(八分)
    note_rom[i]=3;  beat_rom[i]=2; i=i+1;
    note_rom[i]=2;  beat_rom[i]=1; i=i+1;
    note_rom[i]=1;  beat_rom[i]=1; i=i+1;
    // 小节13: 低7(四分) 低7(八分) 1(八分)
    note_rom[i]=14; beat_rom[i]=2; i=i+1;
    note_rom[i]=14; beat_rom[i]=1; i=i+1;
    note_rom[i]=1;  beat_rom[i]=1; i=i+1;
    // 小节14: 2(四分) 3(四分)
    note_rom[i]=2;  beat_rom[i]=2; i=i+1;
    note_rom[i]=3;  beat_rom[i]=2; i=i+1;
    // 小节15: 1(四分) 低6(四分)
    note_rom[i]=1;  beat_rom[i]=2; i=i+1;
    note_rom[i]=13; beat_rom[i]=2; i=i+1;
    // 小节16: 低6(二分)
    note_rom[i]=13; beat_rom[i]=4; i=i+1;

    // ===================== A段反复（完整重复第1-16小节） =====================
    // 小节1
    note_rom[i]=3;  beat_rom[i]=2; i=i+1;
    note_rom[i]=14; beat_rom[i]=1; i=i+1;
    note_rom[i]=1;  beat_rom[i]=1; i=i+1;
    // 小节2
    note_rom[i]=2;  beat_rom[i]=2; i=i+1;
    note_rom[i]=1;  beat_rom[i]=1; i=i+1;
    note_rom[i]=14; beat_rom[i]=1; i=i+1;
    // 小节3
    note_rom[i]=13; beat_rom[i]=2; i=i+1;
    note_rom[i]=13; beat_rom[i]=1; i=i+1;
    note_rom[i]=1;  beat_rom[i]=1; i=i+1;
    // 小节4
    note_rom[i]=3;  beat_rom[i]=2; i=i+1;
    note_rom[i]=2;  beat_rom[i]=1; i=i+1;
    note_rom[i]=1;  beat_rom[i]=1; i=i+1;
    // 小节5
    note_rom[i]=14; beat_rom[i]=2; i=i+1;
    note_rom[i]=14; beat_rom[i]=1; i=i+1;
    note_rom[i]=1;  beat_rom[i]=1; i=i+1;
    // 小节6
    note_rom[i]=2;  beat_rom[i]=2; i=i+1;
    note_rom[i]=3;  beat_rom[i]=2; i=i+1;
    // 小节7
    note_rom[i]=1;  beat_rom[i]=2; i=i+1;
    note_rom[i]=13; beat_rom[i]=2; i=i+1;
    // 小节8
    note_rom[i]=13; beat_rom[i]=4; i=i+1;

    // 小节9
    note_rom[i]=2;  beat_rom[i]=2; i=i+1;
    note_rom[i]=2;  beat_rom[i]=1; i=i+1;
    note_rom[i]=4;  beat_rom[i]=1; i=i+1;
    // 小节10
    note_rom[i]=6;  beat_rom[i]=2; i=i+1;
    note_rom[i]=5;  beat_rom[i]=1; i=i+1;
    note_rom[i]=4;  beat_rom[i]=1; i=i+1;
    // 小节11
    note_rom[i]=3;  beat_rom[i]=2; i=i+1;
    note_rom[i]=3;  beat_rom[i]=1; i=i+1;
    note_rom[i]=1;  beat_rom[i]=1; i=i+1;
    // 小节12
    note_rom[i]=3;  beat_rom[i]=2; i=i+1;
    note_rom[i]=2;  beat_rom[i]=1; i=i+1;
    note_rom[i]=1;  beat_rom[i]=1; i=i+1;
    // 小节13
    note_rom[i]=14; beat_rom[i]=2; i=i+1;
    note_rom[i]=14; beat_rom[i]=1; i=i+1;
    note_rom[i]=1;  beat_rom[i]=1; i=i+1;
    // 小节14
    note_rom[i]=2;  beat_rom[i]=2; i=i+1;
    note_rom[i]=3;  beat_rom[i]=2; i=i+1;
    // 小节15
    note_rom[i]=1;  beat_rom[i]=2; i=i+1;
    note_rom[i]=13; beat_rom[i]=2; i=i+1;
    // 小节16
    note_rom[i]=13; beat_rom[i]=4; i=i+1;

    // ===================== B段（第17-24小节） =====================
    // 小节17: 休止(四分) + 3(四分)
    note_rom[i]=0;  beat_rom[i]=2; i=i+1;
    note_rom[i]=3;  beat_rom[i]=2; i=i+1;
    // 小节18: 6(附点四分) + 低7(八分)
    note_rom[i]=6;  beat_rom[i]=3; i=i+1;
    note_rom[i]=14; beat_rom[i]=1; i=i+1;
    // 小节19: 高1(八分) 7(八分) 6(八分) 4(八分)
    note_rom[i]=15; beat_rom[i]=1; i=i+1;   // 高音1 1046Hz
    note_rom[i]=7;  beat_rom[i]=1; i=i+1;
    note_rom[i]=6;  beat_rom[i]=1; i=i+1;
    note_rom[i]=4;  beat_rom[i]=1; i=i+1;
    // 小节20: 2(附点四分) + 3(八分)
    note_rom[i]=2;  beat_rom[i]=3; i=i+1;
    note_rom[i]=3;  beat_rom[i]=1; i=i+1;
    // 小节21: 6(四分) 7(八分) 6(八分)
    note_rom[i]=6;  beat_rom[i]=2; i=i+1;
    note_rom[i]=7;  beat_rom[i]=1; i=i+1;
    note_rom[i]=6;  beat_rom[i]=1; i=i+1;
    // 小节22: 3(附点四分) + 4(八分)
    note_rom[i]=3;  beat_rom[i]=3; i=i+1;
    note_rom[i]=4;  beat_rom[i]=1; i=i+1;
    // 小节23: 3(八分) 2(八分) 1(八分) 低7(八分)
    note_rom[i]=3;  beat_rom[i]=1; i=i+1;
    note_rom[i]=2;  beat_rom[i]=1; i=i+1;
    note_rom[i]=1;  beat_rom[i]=1; i=i+1;
    note_rom[i]=14; beat_rom[i]=1; i=i+1;
    // 小节24: 低6(二分)
    note_rom[i]=13; beat_rom[i]=4; i=i+1;
end

// ------------------------------------------------------------
// 状态机：节拍计时 + 方波生成
// ------------------------------------------------------------
reg [31:0] beat_cnt;        // 当前音符已持续时间计数
reg [6:0]  ptr;             // 当前音符索引 (0~99)
reg [31:0] duration;        // 当前音符总时长（时钟周期数）
reg [31:0] half_prd;        // 当前音符半周期
reg [31:0] pwm_cnt;         // 方波计数器

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        beat_cnt <= 0;
        ptr      <= 0;
        duration <= 0;
        half_prd <= 0;
        pwm_cnt  <= 0;
        buzzer   <= 0;
    end else begin
        // 节拍切换
        if (beat_cnt >= duration) begin
            beat_cnt <= 0;
            // 当前音符持续时长 = 八分音符个数 × 八分音符时钟周期数
            duration <= beat_rom[ptr] * EIGHTH_CNT;
            half_prd <= half_period( note_rom[ptr] );
            // 指针循环
            if (ptr == TOTAL_NOTES - 1)
                ptr <= 0;
            else
                ptr <= ptr + 1;
        end else begin
            beat_cnt <= beat_cnt + 1;
        end

        // 方波输出（50%占空比）
        if (half_prd == 0) begin
            buzzer  <= 0;
            pwm_cnt <= 0;
        end else begin
            if (pwm_cnt >= half_prd - 1) begin
                pwm_cnt <= 0;
                buzzer  <= ~buzzer;
            end else begin
                pwm_cnt <= pwm_cnt + 1;
            end
        end
    end
end

endmodule