module tetris_core #(
    parameter CLK_FREQ = 50_000_000
)(
    input         clk,
    input         rst_n,
    input  [2:0]  difficulty,
    input         key_rotate,
    input         key_left,
    input         key_right,
    input         key_drop,
    input         key_start,
    output reg [1:0] game_state,
    output reg [16:0] score,
    output reg [19:0] score_bcd,
    output reg        score_changed,
    input      [5:0]  pixel_index,
    output reg [23:0] pixel_rgb
);

localparam ST_INIT  = 2'd0;
localparam ST_RUN   = 2'd1;
localparam ST_PAUSE = 2'd2;
localparam ST_OVER  = 2'd3;

localparam PIECE_I = 3'd0;
localparam PIECE_O = 3'd1;
localparam PIECE_T = 3'd2;
localparam PIECE_L = 3'd3;
localparam PIECE_J = 3'd4;
localparam PIECE_S = 3'd5;
localparam PIECE_Z = 3'd6;

localparam COLOR_OFF    = 24'h000000;
localparam COLOR_I      = 24'h000018;
localparam COLOR_O      = 24'h181800;
localparam COLOR_T      = 24'h180018;
localparam COLOR_L      = 24'h180800;
localparam COLOR_J      = 24'h001818;
localparam COLOR_S      = 24'h001800;
localparam COLOR_Z      = 24'h180000;
localparam COLOR_TEXT   = 24'h040408;

reg [63:0] board_occ;
reg [2:0]  board_type [0:63];
reg [2:0]  cur_type;
reg [1:0]  cur_rot;
reg signed [4:0] cur_x;
reg signed [4:0] cur_y;
reg        piece_active;
reg        spawn_pending;
reg [27:0] drop_cnt;
reg [23:0] text_cnt;
reg [5:0]  text_scroll;
reg [15:0] lfsr;

reg [63:0] tmp_occ;
reg [63:0] new_occ;
reg [2:0]  tmp_type [0:63];
reg [2:0]  new_type [0:63];
reg [2:0]  clear_lines;
reg        row_full;
integer i;
integer r;
integer c;
integer b;
integer wr;
reg signed [4:0] next_y;
reg [2:0] spawn_type;
reg [16:0] next_score;

wire [27:0] drop_limit = speed_cycles(difficulty);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        game_state    <= ST_INIT;
        score         <= 17'd0;
        score_bcd     <= 20'd0;
        score_changed <= 1'b0;
        board_occ     <= 64'd0;
        cur_type      <= PIECE_I;
        cur_rot       <= 2'd0;
        cur_x         <= 5'sd2;
        cur_y         <= 5'sd0;
        piece_active  <= 1'b0;
        spawn_pending <= 1'b0;
        drop_cnt      <= 28'd0;
        text_cnt      <= 24'd0;
        text_scroll   <= 6'd0;
        lfsr          <= 16'hace1;
        for (i = 0; i < 64; i = i + 1)
            board_type[i] <= PIECE_I;
    end else begin
        score_changed <= 1'b0;
        lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};

        if (text_cnt >= CLK_FREQ / 5 - 1) begin
            text_cnt <= 24'd0;
            if (text_scroll >= 6'd55)
                text_scroll <= 6'd0;
            else
                text_scroll <= text_scroll + 6'd1;
        end else begin
            text_cnt <= text_cnt + 24'd1;
        end

        case (game_state)
            ST_INIT: begin
                drop_cnt      <= 28'd0;
                piece_active  <= 1'b0;
                spawn_pending <= 1'b0;
                if (key_start) begin
                    board_occ <= 64'd0;
                    for (i = 0; i < 64; i = i + 1)
                        board_type[i] <= PIECE_I;
                    score         <= 17'd0;
                    score_bcd     <= 20'd0;
                    score_changed <= 1'b0;
                    cur_type      <= rand_piece(lfsr);
                    cur_rot       <= 2'd0;
                    cur_x         <= 5'sd2;
                    cur_y         <= 5'sd0;
                    piece_active  <= 1'b1;
                    game_state    <= ST_RUN;
                    text_scroll   <= 6'd0;
                end
            end

            ST_RUN: begin
                if (key_start) begin
                    game_state <= ST_PAUSE;
                    text_scroll <= 6'd0;
                end else if (spawn_pending) begin
                    spawn_type = rand_piece(lfsr);
                    if (collision_at(spawn_type, 2'd0, 5'sd2, 5'sd0)) begin
                        game_state    <= ST_OVER;
                        spawn_pending <= 1'b0;
                        piece_active  <= 1'b0;
                        text_scroll   <= 6'd0;
                    end else begin
                        cur_type      <= spawn_type;
                        cur_rot       <= 2'd0;
                        cur_x         <= 5'sd2;
                        cur_y         <= 5'sd0;
                        piece_active  <= 1'b1;
                        spawn_pending <= 1'b0;
                    end
                end else if (piece_active) begin
                    if (key_rotate && !collision_at(cur_type, cur_rot + 2'd1, cur_x, cur_y))
                        cur_rot <= cur_rot + 2'd1;
                    else if (key_left && !collision_at(cur_type, cur_rot, cur_x - 5'sd1, cur_y))
                        cur_x <= cur_x - 5'sd1;
                    else if (key_right && !collision_at(cur_type, cur_rot, cur_x + 5'sd1, cur_y))
                        cur_x <= cur_x + 5'sd1;
                    else if (key_drop) begin
                        next_y = cur_y;
                        for (b = 0; b < 8; b = b + 1) begin
                            if (!collision_at(cur_type, cur_rot, cur_x, next_y + 5'sd1))
                                next_y = next_y + 5'sd1;
                        end
                        cur_y = next_y;
                        lock_piece;
                        drop_cnt <= 28'd0;
                    end else if (drop_cnt >= drop_limit - 1) begin
                        drop_cnt <= 28'd0;
                        if (!collision_at(cur_type, cur_rot, cur_x, cur_y + 5'sd1))
                            cur_y <= cur_y + 5'sd1;
                        else
                            lock_piece;
                    end else begin
                        drop_cnt <= drop_cnt + 28'd1;
                    end
                end
            end

            ST_PAUSE: begin
                if (key_start) begin
                    game_state <= ST_RUN;
                    text_scroll <= 6'd0;
                end
            end

            ST_OVER: begin
                piece_active  <= 1'b0;
                spawn_pending <= 1'b0;
                if (key_start) begin
                    game_state <= ST_INIT;
                    text_scroll <= 6'd0;
                end
            end

            default: game_state <= ST_INIT;
        endcase
    end
end

task lock_piece;
    begin
        tmp_occ = board_occ;
        for (i = 0; i < 64; i = i + 1)
            tmp_type[i] = board_type[i];

        for (b = 0; b < 4; b = b + 1) begin
            tmp_occ[(cur_y + block_y(cur_type, cur_rot, b))*8 + (cur_x + block_x(cur_type, cur_rot, b))] = 1'b1;
            tmp_type[(cur_y + block_y(cur_type, cur_rot, b))*8 + (cur_x + block_x(cur_type, cur_rot, b))] = cur_type;
        end

        new_occ = 64'd0;
        for (i = 0; i < 64; i = i + 1)
            new_type[i] = PIECE_I;

        clear_lines = 3'd0;
        wr = 7;
        for (r = 7; r >= 0; r = r - 1) begin
            row_full = 1'b1;
            for (c = 0; c < 8; c = c + 1)
                if (!tmp_occ[r*8 + c])
                    row_full = 1'b0;

            if (row_full) begin
                clear_lines = clear_lines + 3'd1;
            end else begin
                for (c = 0; c < 8; c = c + 1) begin
                    new_occ[wr*8 + c] = tmp_occ[r*8 + c];
                    new_type[wr*8 + c] = tmp_type[r*8 + c];
                end
                wr = wr - 1;
            end
        end

        board_occ <= new_occ;
        for (i = 0; i < 64; i = i + 1)
            board_type[i] <= new_type[i];

        if (clear_lines != 3'd0) begin
            next_score = score + clear_lines * 17'd100;
            if (next_score > 17'd99999)
                score <= 17'd99999;
            else
                score <= next_score;
            score_bcd <= bcd_add_score(score_bcd, clear_lines);
            score_changed <= 1'b1;
        end

        piece_active  <= 1'b0;
        spawn_pending <= 1'b1;
    end
endtask

always @(*) begin : pixel_color_comb
    integer pix_i;
    pixel_rgb = COLOR_OFF;
    if (game_state == ST_RUN) begin
        if (board_occ[pixel_index])
            pixel_rgb = piece_color(board_type[pixel_index]);

        if (piece_active) begin
            for (pix_i = 0; pix_i < 4; pix_i = pix_i + 1) begin
                if ((pixel_index[2:0] == cur_x + block_x(cur_type, cur_rot, pix_i)) &&
                    (pixel_index[5:3] == cur_y + block_y(cur_type, cur_rot, pix_i)))
                    pixel_rgb = piece_color(cur_type);
            end
        end
    end else begin
        if (text_pixel(game_state, pixel_index[5:3], pixel_index[2:0], text_scroll))
            pixel_rgb = COLOR_TEXT;
    end
end

function [27:0] speed_cycles;
    input [2:0] level;
    begin
        case (level)
            3'd1: speed_cycles = 28'd100_000_000;
            3'd2: speed_cycles = 28'd81_250_000;
            3'd3: speed_cycles = 28'd62_500_000;
            3'd4: speed_cycles = 28'd43_750_000;
            3'd5: speed_cycles = 28'd25_000_000;
            default: speed_cycles = 28'd100_000_000;
        endcase
    end
endfunction

function [2:0] rand_piece;
    input [15:0] rnd;
    begin
        if (rnd[2:0] < 3'd7)
            rand_piece = rnd[2:0];
        else
            rand_piece = 3'd0;
    end
endfunction

function [19:0] bcd_add_score;
    input [19:0] current;
    input [2:0] lines;
    reg [3:0] d4;
    reg [3:0] d3;
    reg [3:0] d2;
    reg [3:0] add_hundreds;
    begin
        d4 = current[19:16];
        d3 = current[15:12];
        d2 = current[11:8];
        add_hundreds = {1'b0, lines};
        if (current == 20'h99999) begin
            bcd_add_score = 20'h99999;
        end else begin
            d2 = d2 + add_hundreds;
            if (d2 >= 4'd10) begin
                d2 = d2 - 4'd10;
                d3 = d3 + 4'd1;
            end
            if (d3 >= 4'd10) begin
                d3 = d3 - 4'd10;
                d4 = d4 + 4'd1;
            end
            if (d4 >= 4'd10)
                bcd_add_score = 20'h99999;
            else
                bcd_add_score = {d4, d3, d2, 8'h00};
        end
    end
endfunction

function collision_at;
    input [2:0] ptype;
    input [1:0] prot;
    input signed [4:0] px;
    input signed [4:0] py;
    reg signed [4:0] bx;
    reg signed [4:0] by;
    integer k;
    begin
        collision_at = 1'b0;
        for (k = 0; k < 4; k = k + 1) begin
            bx = px + block_x(ptype, prot, k);
            by = py + block_y(ptype, prot, k);
            if (bx < 0 || bx > 7 || by < 0 || by > 7)
                collision_at = 1'b1;
            else if (board_occ[by*8 + bx])
                collision_at = 1'b1;
        end
    end
endfunction

function signed [4:0] block_x;
    input [2:0] ptype;
    input [1:0] prot;
    input integer idx;
    begin
        block_x = 5'sd0;
        case (ptype)
            PIECE_I: block_x = (prot[0] == 1'b0) ? idx[4:0] : 5'sd1;
            PIECE_O: block_x = (idx == 0 || idx == 2) ? 5'sd1 : 5'sd2;
            PIECE_T: begin
                case (prot)
                    2'd0: block_x = (idx == 0) ? 5'sd1 : (idx == 1) ? 5'sd0 : (idx == 2) ? 5'sd1 : 5'sd2;
                    2'd1: block_x = (idx == 0) ? 5'sd1 : (idx == 1) ? 5'sd1 : (idx == 2) ? 5'sd2 : 5'sd1;
                    2'd2: block_x = (idx == 0) ? 5'sd0 : (idx == 1) ? 5'sd1 : (idx == 2) ? 5'sd2 : 5'sd1;
                    default: block_x = (idx == 0) ? 5'sd1 : (idx == 1) ? 5'sd0 : (idx == 2) ? 5'sd1 : 5'sd1;
                endcase
            end
            PIECE_L: begin
                case (prot)
                    2'd0: block_x = (idx == 3) ? 5'sd2 : idx[4:0];
                    2'd1: block_x = (idx == 3) ? 5'sd2 : 5'sd1;
                    2'd2: block_x = (idx == 3) ? 5'sd0 : idx[4:0];
                    default: block_x = (idx == 3) ? 5'sd0 : 5'sd1;
                endcase
            end
            PIECE_J: begin
                case (prot)
                    2'd0: block_x = (idx == 0) ? 5'sd0 : idx[4:0] - 5'sd1;
                    2'd1: block_x = (idx == 1) ? 5'sd2 : 5'sd1;
                    2'd2: block_x = (idx == 3) ? 5'sd2 : idx[4:0];
                    default: block_x = (idx == 2) ? 5'sd0 : 5'sd1;
                endcase
            end
            PIECE_S: block_x = (prot[0] == 1'b0) ? ((idx == 0) ? 5'sd1 : (idx == 1) ? 5'sd2 : (idx == 2) ? 5'sd0 : 5'sd1) :
                                             ((idx == 0) ? 5'sd1 : (idx == 1) ? 5'sd1 : (idx == 2) ? 5'sd2 : 5'sd2);
            PIECE_Z: block_x = (prot[0] == 1'b0) ? ((idx == 0) ? 5'sd0 : (idx == 1) ? 5'sd1 : (idx == 2) ? 5'sd1 : 5'sd2) :
                                             ((idx == 0) ? 5'sd2 : (idx == 1) ? 5'sd1 : (idx == 2) ? 5'sd2 : 5'sd1);
            default: block_x = 5'sd0;
        endcase
    end
endfunction

function signed [4:0] block_y;
    input [2:0] ptype;
    input [1:0] prot;
    input integer idx;
    begin
        block_y = 5'sd0;
        case (ptype)
            PIECE_I: block_y = (prot[0] == 1'b0) ? 5'sd1 : idx[4:0];
            PIECE_O: block_y = (idx < 2) ? 5'sd0 : 5'sd1;
            PIECE_T: begin
                case (prot)
                    2'd0: block_y = (idx == 0) ? 5'sd0 : 5'sd1;
                    2'd1: block_y = (idx == 0) ? 5'sd0 : (idx == 1) ? 5'sd1 : (idx == 2) ? 5'sd1 : 5'sd2;
                    2'd2: block_y = (idx == 0) ? 5'sd0 : (idx == 1) ? 5'sd0 : (idx == 2) ? 5'sd0 : 5'sd1;
                    default: block_y = (idx == 0) ? 5'sd0 : (idx == 1) ? 5'sd1 : (idx == 2) ? 5'sd1 : 5'sd2;
                endcase
            end
            PIECE_L: begin
                case (prot)
                    2'd0: block_y = (idx == 3) ? 5'sd1 : 5'sd0;
                    2'd1: block_y = (idx == 3) ? 5'sd2 : idx[4:0];
                    2'd2: block_y = (idx == 3) ? 5'sd2 : 5'sd1;
                    default: block_y = (idx == 3) ? 5'sd0 : idx[4:0];
                endcase
            end
            PIECE_J: begin
                case (prot)
                    2'd0: block_y = (idx == 0) ? 5'sd0 : 5'sd1;
                    2'd1: block_y = (idx == 1) ? 5'sd0 : (idx == 0) ? 5'sd0 : (idx == 2) ? 5'sd1 : 5'sd2;
                    2'd2: block_y = (idx == 3) ? 5'sd2 : 5'sd1;
                    default: block_y = (idx < 2) ? idx[4:0] : 5'sd2;
                endcase
            end
            PIECE_S: block_y = (prot[0] == 1'b0) ? ((idx < 2) ? 5'sd0 : 5'sd1) :
                                             ((idx == 0) ? 5'sd0 : (idx == 1) ? 5'sd1 : (idx == 2) ? 5'sd1 : 5'sd2);
            PIECE_Z: block_y = (prot[0] == 1'b0) ? ((idx < 2) ? 5'sd0 : 5'sd1) :
                                             ((idx == 0) ? 5'sd0 : (idx == 1) ? 5'sd1 : (idx == 2) ? 5'sd1 : 5'sd2);
            default: block_y = 5'sd0;
        endcase
    end
endfunction

function [23:0] piece_color;
    input [2:0] ptype;
    begin
        case (ptype)
            PIECE_I: piece_color = COLOR_I;
            PIECE_O: piece_color = COLOR_O;
            PIECE_T: piece_color = COLOR_T;
            PIECE_L: piece_color = COLOR_L;
            PIECE_J: piece_color = COLOR_J;
            PIECE_S: piece_color = COLOR_S;
            PIECE_Z: piece_color = COLOR_Z;
            default: piece_color = COLOR_OFF;
        endcase
    end
endfunction

function text_pixel;
    input [1:0] state;
    input [2:0] row;
    input [2:0] col;
    input [5:0] scroll;
    reg [5:0] actual_col;
    reg [3:0] char_pos;
    reg [2:0] char_col;
    reg [3:0] char_id;
    reg [5:0] total_cols;
    reg [5:0] col_tmp;
    begin
        col_tmp = 6'd0;
        if (state == ST_INIT)
            total_cols = 6'd30;
        else if (state == ST_PAUSE)
            total_cols = 6'd30;
        else
            total_cols = 6'd48;

        actual_col = col + scroll;
        if (actual_col >= total_cols)
            actual_col = actual_col - total_cols;

        if (actual_col < 6'd6) begin
            char_pos = 4'd0;
            char_col = actual_col[2:0];
        end else if (actual_col < 6'd12) begin
            char_pos = 4'd1;
            col_tmp = actual_col - 6'd6;
            char_col = col_tmp[2:0];
        end else if (actual_col < 6'd18) begin
            char_pos = 4'd2;
            col_tmp = actual_col - 6'd12;
            char_col = col_tmp[2:0];
        end else if (actual_col < 6'd24) begin
            char_pos = 4'd3;
            col_tmp = actual_col - 6'd18;
            char_col = col_tmp[2:0];
        end else if (actual_col < 6'd30) begin
            char_pos = 4'd4;
            col_tmp = actual_col - 6'd24;
            char_col = col_tmp[2:0];
        end else if (actual_col < 6'd36) begin
            char_pos = 4'd5;
            col_tmp = actual_col - 6'd30;
            char_col = col_tmp[2:0];
        end else if (actual_col < 6'd42) begin
            char_pos = 4'd6;
            col_tmp = actual_col - 6'd36;
            char_col = col_tmp[2:0];
        end else begin
            char_pos = 4'd7;
            col_tmp = actual_col - 6'd42;
            char_col = col_tmp[2:0];
        end
        char_id = message_char(state, char_pos);
        if (char_col == 3'd5 || row == 3'd7)
            text_pixel = 1'b0;
        else
            text_pixel = font_pixel(char_id, row, char_col);
    end
endfunction

function [3:0] message_char;
    input [1:0] state;
    input [3:0] pos;
    begin
        message_char = 4'd0;
        if (state == ST_INIT) begin
            case (pos)
                4'd0: message_char = 4'd0; // S
                4'd1: message_char = 4'd1; // T
                4'd2: message_char = 4'd2; // A
                4'd3: message_char = 4'd3; // R
                4'd4: message_char = 4'd1; // T
                default: message_char = 4'd0;
            endcase
        end else if (state == ST_PAUSE) begin
            case (pos)
                4'd0: message_char = 4'd4; // P
                4'd1: message_char = 4'd2; // A
                4'd2: message_char = 4'd5; // U
                4'd3: message_char = 4'd0; // S
                4'd4: message_char = 4'd6; // E
                default: message_char = 4'd4;
            endcase
        end else begin
            case (pos)
                4'd0: message_char = 4'd7;  // G
                4'd1: message_char = 4'd2;  // A
                4'd2: message_char = 4'd8;  // M
                4'd3: message_char = 4'd6;  // E
                4'd4: message_char = 4'd9;  // O
                4'd5: message_char = 4'd10; // V
                4'd6: message_char = 4'd6;  // E
                4'd7: message_char = 4'd3;  // R
                default: message_char = 4'd7;
            endcase
        end
    end
endfunction

function font_pixel;
    input [3:0] ch;
    input [2:0] row;
    input [2:0] col;
    reg [4:0] bits;
    begin
        bits = 5'b00000;
        case (ch)
            4'd0: case (row) 0:bits=5'b11111;1:bits=5'b10000;2:bits=5'b10000;3:bits=5'b11110;4:bits=5'b00001;5:bits=5'b00001;6:bits=5'b11110;default:bits=0;endcase
            4'd1: case (row) 0:bits=5'b11111;1:bits=5'b00100;2:bits=5'b00100;3:bits=5'b00100;4:bits=5'b00100;5:bits=5'b00100;6:bits=5'b00100;default:bits=0;endcase
            4'd2: case (row) 0:bits=5'b01110;1:bits=5'b10001;2:bits=5'b10001;3:bits=5'b11111;4:bits=5'b10001;5:bits=5'b10001;6:bits=5'b10001;default:bits=0;endcase
            4'd3: case (row) 0:bits=5'b11110;1:bits=5'b10001;2:bits=5'b10001;3:bits=5'b11110;4:bits=5'b10100;5:bits=5'b10010;6:bits=5'b10001;default:bits=0;endcase
            4'd4: case (row) 0:bits=5'b11110;1:bits=5'b10001;2:bits=5'b10001;3:bits=5'b11110;4:bits=5'b10000;5:bits=5'b10000;6:bits=5'b10000;default:bits=0;endcase
            4'd5: case (row) 0:bits=5'b10001;1:bits=5'b10001;2:bits=5'b10001;3:bits=5'b10001;4:bits=5'b10001;5:bits=5'b10001;6:bits=5'b01110;default:bits=0;endcase
            4'd6: case (row) 0:bits=5'b11111;1:bits=5'b10000;2:bits=5'b10000;3:bits=5'b11110;4:bits=5'b10000;5:bits=5'b10000;6:bits=5'b11111;default:bits=0;endcase
            4'd7: case (row) 0:bits=5'b01111;1:bits=5'b10000;2:bits=5'b10000;3:bits=5'b10111;4:bits=5'b10001;5:bits=5'b10001;6:bits=5'b01111;default:bits=0;endcase
            4'd8: case (row) 0:bits=5'b10001;1:bits=5'b11011;2:bits=5'b10101;3:bits=5'b10101;4:bits=5'b10001;5:bits=5'b10001;6:bits=5'b10001;default:bits=0;endcase
            4'd9: case (row) 0:bits=5'b01110;1:bits=5'b10001;2:bits=5'b10001;3:bits=5'b10001;4:bits=5'b10001;5:bits=5'b10001;6:bits=5'b01110;default:bits=0;endcase
            4'd10:case (row) 0:bits=5'b10001;1:bits=5'b10001;2:bits=5'b10001;3:bits=5'b01010;4:bits=5'b01010;5:bits=5'b00100;6:bits=5'b00100;default:bits=0;endcase
            default: bits = 5'b00000;
        endcase
        font_pixel = bits[4 - col];
    end
endfunction

endmodule
