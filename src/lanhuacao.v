// Orchid Grass / Lan Hua Cao buzzer player
// clk_50m: 50 MHz system clock
// key_start_pause: push once to start, push again to pause
// buzzer: connect to the BUZZER drive input in the transistor buzzer circuit

module lanhuacao #(
    parameter KEY_ACTIVE_LEVEL = 1'b0      // common FPGA buttons are active-low
) (
    input  wire clk_50m,
    input  wire rst_n,
    input  wire key_start_pause,
    output reg  buzzer
);

    localparam integer EIGHTH_TICKS    = 15_625_000; // 96 BPM, eighth note = 312.5 ms
    localparam integer NOTE_GAP_TICKS  = 1_953_125;  // 1/8 of an eighth note, separates repeated notes
    localparam integer DEBOUNCE_TICKS  = 1_000_000;  // 20 ms at 50 MHz
    localparam integer SONG_LEN        = 115;

    localparam [1:0] S_IDLE = 2'd0;
    localparam [1:0] S_PLAY = 2'd1;
    localparam [1:0] S_NEXT = 2'd2;

    localparam [4:0] N_REST = 5'd0;

    localparam [4:0] N_M1 = 5'd1,  N_M2 = 5'd2,  N_M3 = 5'd3,  N_M4 = 5'd4;
    localparam [4:0] N_M5 = 5'd5,  N_M6 = 5'd6,  N_M7 = 5'd7;

    localparam [4:0] N_L1 = 5'd8,  N_L2 = 5'd9,  N_L3 = 5'd10, N_L4 = 5'd11;
    localparam [4:0] N_L5 = 5'd12, N_L6 = 5'd13, N_L7 = 5'd14;

    localparam [4:0] N_H1 = 5'd15, N_H2 = 5'd16, N_H3 = 5'd17, N_H4 = 5'd18;
    localparam [4:0] N_H5 = 5'd19, N_H6 = 5'd20, N_H7 = 5'd21;
    localparam [4:0] N_M4S = 5'd22; // sharp 4, about 740 Hz

    reg [1:0]  state;
    reg        playing;
    reg [7:0]  note_index;
    reg [31:0] duration_cnt;
    reg [31:0] freq_cnt;

    wire [4:0]  current_note;
    wire [3:0]  current_eighths;
    wire [31:0] current_half_period;
    wire [31:0] current_duration_ticks;
    wire        note_done;
    wire        note_sound_enable;

    assign current_note           = note_rom(note_index);
    assign current_eighths        = dur_rom(note_index);
    assign current_half_period    = half_period(current_note);
    assign current_duration_ticks = EIGHTH_TICKS * current_eighths;
    assign note_done              = (duration_cnt >= current_duration_ticks - 1);
    assign note_sound_enable      = (duration_cnt < current_duration_ticks - NOTE_GAP_TICKS);

    // ------------------------------
    // Button debounce and edge detect
    // ------------------------------
    reg key_sync0;
    reg key_sync1;
    reg key_stable;
    reg key_stable_d;
    reg [19:0] key_cnt;

    wire key_pressed_raw = (key_sync1 == KEY_ACTIVE_LEVEL);
    wire key_posedge     = key_stable & ~key_stable_d;

    always @(posedge clk_50m or negedge rst_n) begin
        if (!rst_n) begin
            key_sync0    <= ~KEY_ACTIVE_LEVEL;
            key_sync1    <= ~KEY_ACTIVE_LEVEL;
            key_stable   <= 1'b0;
            key_stable_d <= 1'b0;
            key_cnt      <= 20'd0;
        end else begin
            key_sync0 <= key_start_pause;
            key_sync1 <= key_sync0;

            key_stable_d <= key_stable;

            if (key_pressed_raw == key_stable) begin
                key_cnt <= 20'd0;
            end else if (key_cnt == DEBOUNCE_TICKS - 1) begin
                key_stable <= key_pressed_raw;
                key_cnt    <= 20'd0;
            end else begin
                key_cnt <= key_cnt + 1'b1;
            end
        end
    end

    // ------------------------------
    // Three-state music FSM
    // ------------------------------
    always @(posedge clk_50m or negedge rst_n) begin
        if (!rst_n) begin
            state        <= S_IDLE;
            playing      <= 1'b0;
            note_index   <= 8'd0;
            duration_cnt <= 32'd0;
            freq_cnt     <= 32'd0;
            buzzer       <= 1'b0;
        end else begin
            if (key_posedge) begin
                playing <= ~playing;
            end

            if (!playing) begin
                buzzer   <= 1'b0;
                freq_cnt <= 32'd0;
            end else begin
                case (state)
                    S_IDLE: begin
                        state        <= S_PLAY;
                        duration_cnt <= 32'd0;
                        freq_cnt     <= 32'd0;
                        buzzer       <= 1'b0;
                    end

                    S_PLAY: begin
                        if ((current_note == N_REST) || !note_sound_enable) begin
                            buzzer   <= 1'b0;
                            freq_cnt <= 32'd0;
                        end else if (freq_cnt >= current_half_period - 1) begin
                            freq_cnt <= 32'd0;
                            buzzer   <= ~buzzer;
                        end else begin
                            freq_cnt <= freq_cnt + 1'b1;
                        end

                        if (note_done) begin
                            state <= S_NEXT;
                        end else begin
                            duration_cnt <= duration_cnt + 1'b1;
                        end
                    end

                    S_NEXT: begin
                        state        <= S_PLAY;
                        duration_cnt <= 32'd0;
                        freq_cnt     <= 32'd0;
                        buzzer       <= 1'b0;

                        if (note_index == SONG_LEN - 1) begin
                            note_index <= 8'd0;
                        end else begin
                            note_index <= note_index + 1'b1;
                        end
                    end

                    default: begin
                        state <= S_IDLE;
                    end
                endcase
            end
        end
    end

    // 50% duty-cycle divider values: half_period = 50_000_000 / (2 * frequency)
    function [31:0] half_period;
        input [4:0] note;
        begin
            case (note)
                N_L1: half_period = 32'd95785; // 261 Hz
                N_L2: half_period = 32'd85324; // 293 Hz
                N_L3: half_period = 32'd75988; // 329 Hz
                N_L4: half_period = 32'd71633; // 349 Hz
                N_L5: half_period = 32'd63776; // 392 Hz
                N_L6: half_period = 32'd56818; // 440 Hz
                N_L7: half_period = 32'd50100; // 499 Hz

                N_M1: half_period = 32'd47801; // 523 Hz
                N_M2: half_period = 32'd42589; // 587 Hz
                N_M3: half_period = 32'd37936; // 659 Hz
                N_M4: half_period = 32'd35817; // 698 Hz
                N_M4S: half_period = 32'd33784; // 740 Hz
                N_M5: half_period = 32'd31888; // 784 Hz
                N_M6: half_period = 32'd28409; // 880 Hz
                N_M7: half_period = 32'd25050; // 998 Hz

                N_H1: half_period = 32'd23900; // 1046 Hz
                N_H2: half_period = 32'd21295; // 1174 Hz
                N_H3: half_period = 32'd18968; // 1318 Hz
                N_H4: half_period = 32'd17908; // 1396 Hz
                N_H5: half_period = 32'd15944; // 1568 Hz
                N_H6: half_period = 32'd14205; // 1760 Hz
                N_H7: half_period = 32'd12652; // 1976 Hz

                default: half_period = 32'd1;
            endcase
        end
    endfunction

    // Notes are transcribed from the provided numbered score.
    // Duration unit is eighth note: 1=eighth, 2=quarter, 3=dotted quarter, 4=half.
    function [4:0] note_rom;
        input [7:0] addr;
        begin
            case (addr)
                // Intro
                8'd0: note_rom = N_M3;  8'd1: note_rom = N_M6;  8'd2: note_rom = N_M6;  8'd3: note_rom = N_M5;
                8'd4: note_rom = N_M3;  8'd5: note_rom = N_M2;  8'd6: note_rom = N_M1;  8'd7: note_rom = N_M2;
                8'd8: note_rom = N_M1;  8'd9: note_rom = N_L7;  8'd10: note_rom = N_L6; 8'd11: note_rom = N_L3;
                8'd12: note_rom = N_L3; 8'd13: note_rom = N_M1; 8'd14: note_rom = N_M1; 8'd15: note_rom = N_L7;
                8'd16: note_rom = N_L6; 8'd17: note_rom = N_L3; 8'd18: note_rom = N_M2; 8'd19: note_rom = N_M1;
                8'd20: note_rom = N_L7; 8'd21: note_rom = N_L5; 8'd22: note_rom = N_L6;

                // Verse
                8'd23: note_rom = N_L6; 8'd24: note_rom = N_M3; 8'd25: note_rom = N_M3; 8'd26: note_rom = N_M3;
                8'd27: note_rom = N_M3; 8'd28: note_rom = N_M2; 8'd29: note_rom = N_M1; 8'd30: note_rom = N_M2;
                8'd31: note_rom = N_M1; 8'd32: note_rom = N_L7; 8'd33: note_rom = N_L6;

                8'd34: note_rom = N_M6; 8'd35: note_rom = N_M6; 8'd36: note_rom = N_M6; 8'd37: note_rom = N_M6;
                8'd38: note_rom = N_M6; 8'd39: note_rom = N_M5; 8'd40: note_rom = N_M3; 8'd41: note_rom = N_M5;
                8'd42: note_rom = N_M5; 8'd43: note_rom = N_M4S; 8'd44: note_rom = N_M3;

                8'd45: note_rom = N_M3; 8'd46: note_rom = N_M6; 8'd47: note_rom = N_M6; 8'd48: note_rom = N_M5;
                8'd49: note_rom = N_M3; 8'd50: note_rom = N_M2; 8'd51: note_rom = N_M1; 8'd52: note_rom = N_M2;
                8'd53: note_rom = N_M1; 8'd54: note_rom = N_L7; 8'd55: note_rom = N_L6; 8'd56: note_rom = N_L3;

                8'd57: note_rom = N_L3; 8'd58: note_rom = N_M1; 8'd59: note_rom = N_M1; 8'd60: note_rom = N_L7;
                8'd61: note_rom = N_L6; 8'd62: note_rom = N_L3; 8'd63: note_rom = N_M2; 8'd64: note_rom = N_M1;
                8'd65: note_rom = N_L7; 8'd66: note_rom = N_L5; 8'd67: note_rom = N_L6;

                8'd68: note_rom = N_L3; 8'd69: note_rom = N_M1; 8'd70: note_rom = N_M1; 8'd71: note_rom = N_L7;
                8'd72: note_rom = N_L6; 8'd73: note_rom = N_L3; 8'd74: note_rom = N_M2; 8'd75: note_rom = N_M1;
                8'd76: note_rom = N_L7; 8'd77: note_rom = N_L5; 8'd78: note_rom = N_L6;

                // Repeat the visible refrain before looping
                8'd79: note_rom = N_L6; 8'd80: note_rom = N_M3; 8'd81: note_rom = N_M3; 8'd82: note_rom = N_M3;
                8'd83: note_rom = N_M3; 8'd84: note_rom = N_M2; 8'd85: note_rom = N_M1; 8'd86: note_rom = N_M2;
                8'd87: note_rom = N_M1; 8'd88: note_rom = N_L7; 8'd89: note_rom = N_L6;

                8'd90: note_rom = N_M6; 8'd91: note_rom = N_M6; 8'd92: note_rom = N_M6; 8'd93: note_rom = N_M6;
                8'd94: note_rom = N_M6; 8'd95: note_rom = N_M5; 8'd96: note_rom = N_M3; 8'd97: note_rom = N_M5;
                8'd98: note_rom = N_M5; 8'd99: note_rom = N_M4S; 8'd100: note_rom = N_M3;

                8'd101: note_rom = N_M3; 8'd102: note_rom = N_M6; 8'd103: note_rom = N_M6; 8'd104: note_rom = N_M5;
                8'd105: note_rom = N_M3; 8'd106: note_rom = N_M2; 8'd107: note_rom = N_M1; 8'd108: note_rom = N_M2;
                8'd109: note_rom = N_M1; 8'd110: note_rom = N_L7; 8'd111: note_rom = N_L6; 8'd112: note_rom = N_L3;
                8'd113: note_rom = N_M2; 8'd114: note_rom = N_L6;

                default: note_rom = N_REST;
            endcase
        end
    endfunction

    function [3:0] dur_rom;
        input [7:0] addr;
        begin
            case (addr)
                // Intro: 3 6 6 5 3. 2 | 1. 2 1 7 6 3 | ...
                8'd0: dur_rom = 4'd1;   8'd1: dur_rom = 4'd1;   8'd2: dur_rom = 4'd1;   8'd3: dur_rom = 4'd1;
                8'd4: dur_rom = 4'd3;   8'd5: dur_rom = 4'd1;   8'd6: dur_rom = 4'd3;   8'd7: dur_rom = 4'd1;
                8'd8: dur_rom = 4'd1;   8'd9: dur_rom = 4'd1;   8'd10: dur_rom = 4'd2;  8'd11: dur_rom = 4'd2;
                8'd12: dur_rom = 4'd1;  8'd13: dur_rom = 4'd1;  8'd14: dur_rom = 4'd1;  8'd15: dur_rom = 4'd1;
                8'd16: dur_rom = 4'd3;  8'd17: dur_rom = 4'd1;  8'd18: dur_rom = 4'd3;  8'd19: dur_rom = 4'd1;
                8'd20: dur_rom = 4'd1;  8'd21: dur_rom = 4'd1;  8'd22: dur_rom = 4'd4;

                // Verse
                8'd23: dur_rom = 4'd2;  8'd24: dur_rom = 4'd1;  8'd25: dur_rom = 4'd1;  8'd26: dur_rom = 4'd1;
                8'd27: dur_rom = 4'd3;  8'd28: dur_rom = 4'd1;  8'd29: dur_rom = 4'd3;  8'd30: dur_rom = 4'd1;
                8'd31: dur_rom = 4'd1;  8'd32: dur_rom = 4'd1;  8'd33: dur_rom = 4'd4;

                8'd34: dur_rom = 4'd1;  8'd35: dur_rom = 4'd1;  8'd36: dur_rom = 4'd1;  8'd37: dur_rom = 4'd1;
                8'd38: dur_rom = 4'd3;  8'd39: dur_rom = 4'd1;  8'd40: dur_rom = 4'd1;  8'd41: dur_rom = 4'd1;
                8'd42: dur_rom = 4'd1;  8'd43: dur_rom = 4'd1;  8'd44: dur_rom = 4'd4;

                8'd45: dur_rom = 4'd1;  8'd46: dur_rom = 4'd1;  8'd47: dur_rom = 4'd1;  8'd48: dur_rom = 4'd1;
                8'd49: dur_rom = 4'd3;  8'd50: dur_rom = 4'd1;  8'd51: dur_rom = 4'd3;  8'd52: dur_rom = 4'd1;
                8'd53: dur_rom = 4'd1;  8'd54: dur_rom = 4'd1;  8'd55: dur_rom = 4'd2;  8'd56: dur_rom = 4'd2;

                8'd57: dur_rom = 4'd1;  8'd58: dur_rom = 4'd1;  8'd59: dur_rom = 4'd1;  8'd60: dur_rom = 4'd1;
                8'd61: dur_rom = 4'd3;  8'd62: dur_rom = 4'd1;  8'd63: dur_rom = 4'd3;  8'd64: dur_rom = 4'd1;
                8'd65: dur_rom = 4'd1;  8'd66: dur_rom = 4'd1;  8'd67: dur_rom = 4'd4;

                8'd68: dur_rom = 4'd1;  8'd69: dur_rom = 4'd1;  8'd70: dur_rom = 4'd1;  8'd71: dur_rom = 4'd1;
                8'd72: dur_rom = 4'd3;  8'd73: dur_rom = 4'd1;  8'd74: dur_rom = 4'd3;  8'd75: dur_rom = 4'd1;
                8'd76: dur_rom = 4'd1;  8'd77: dur_rom = 4'd1;  8'd78: dur_rom = 4'd4;

                // Refrain repeat
                8'd79: dur_rom = 4'd2;  8'd80: dur_rom = 4'd1;  8'd81: dur_rom = 4'd1;  8'd82: dur_rom = 4'd1;
                8'd83: dur_rom = 4'd3;  8'd84: dur_rom = 4'd1;  8'd85: dur_rom = 4'd3;  8'd86: dur_rom = 4'd1;
                8'd87: dur_rom = 4'd1;  8'd88: dur_rom = 4'd1;  8'd89: dur_rom = 4'd4;

                8'd90: dur_rom = 4'd1;  8'd91: dur_rom = 4'd1;  8'd92: dur_rom = 4'd1;  8'd93: dur_rom = 4'd1;
                8'd94: dur_rom = 4'd3;  8'd95: dur_rom = 4'd1;  8'd96: dur_rom = 4'd1;  8'd97: dur_rom = 4'd1;
                8'd98: dur_rom = 4'd1;  8'd99: dur_rom = 4'd1;  8'd100: dur_rom = 4'd4;

                8'd101: dur_rom = 4'd1; 8'd102: dur_rom = 4'd1; 8'd103: dur_rom = 4'd1; 8'd104: dur_rom = 4'd1;
                8'd105: dur_rom = 4'd3; 8'd106: dur_rom = 4'd1; 8'd107: dur_rom = 4'd3; 8'd108: dur_rom = 4'd1;
                8'd109: dur_rom = 4'd1; 8'd110: dur_rom = 4'd1; 8'd111: dur_rom = 4'd2; 8'd112: dur_rom = 4'd2;
                8'd113: dur_rom = 4'd3; 8'd114: dur_rom = 4'd4;

                default: dur_rom = 4'd2;
            endcase
        end
    endfunction

endmodule
