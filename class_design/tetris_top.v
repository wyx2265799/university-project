module tetris_top (
    input        clk,
    input        key1,
    input        key2,
    input        key3,
    input        key4,
    input        key5,
    input        uart_rxd,
    output       uart_txd,
    output       dq,
    output [5:0] sel,
    output [7:0] seg,
    output       buzzer
);

localparam ST_INIT = 2'd0;
reg [15:0] por_cnt = 16'd0;
reg        rst_n = 1'b0;

always @(posedge clk) begin
    if (por_cnt != 16'hffff) begin
        por_cnt <= por_cnt + 16'd1;
        rst_n   <= 1'b0;
    end else begin
        rst_n <= 1'b1;
    end
end

wire [4:0] key_pulse;
wire [7:0] rx_data;
wire       rx_valid;
wire [1:0] game_state;
wire [19:0] score_bcd;
wire       score_changed;
wire [5:0] pixel_index;
wire [23:0] pixel_rgb;
wire       music_buzzer;
wire       tx_busy;
wire       tx_done;
reg [2:0] difficulty;
reg [19:0] score_tx_bcd;
reg [3:0] tx_idx;
reg       tx_active;
reg       tx_start;
reg [7:0] tx_data;
reg        score_report_pending;
reg [1:0]  game_state_d;

key_debounce #(
    .KEY_WIDTH(5),
    .DEBOUNCE_TIME(1_000_000)
) u_key_debounce (
    .clk        (clk),
    .rst_n      (rst_n),
    .key_n      ({key5, key4, key3, key2, key1}),
    .press_pulse(key_pulse)
);

uart_rx_byte u_uart_rx_byte (
    .clk       (clk),
    .rst_n     (rst_n),
    .uart_rxd  (uart_rxd),
    .data      (rx_data),
    .data_valid(rx_valid)
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        difficulty <= 3'd1;
    end else begin
        if (rx_valid && game_state == ST_INIT) begin
            if (rx_data >= 8'h31 && rx_data <= 8'h35)
                difficulty <= rx_data[2:0];
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        score_tx_bcd <= 20'd0;
        tx_idx       <= 4'd0;
        tx_active    <= 1'b0;
        tx_start     <= 1'b0;
        tx_data      <= 8'hff;
        score_report_pending <= 1'b1;
        game_state_d         <= ST_INIT;
    end else begin
        tx_start <= 1'b0;
        game_state_d <= game_state;

        if (score_changed || (game_state != game_state_d))
            score_report_pending <= 1'b1;

        if (score_report_pending && !tx_active && !tx_busy) begin
            score_tx_bcd <= score_bcd;
            tx_active    <= 1'b1;
            tx_idx       <= 4'd0;
            score_report_pending <= 1'b0;
        end else if (tx_done && tx_active) begin
            if (tx_idx == 4'd8) begin
                tx_active <= 1'b0;
                tx_idx    <= 4'd0;
            end else begin
                tx_idx <= tx_idx + 4'd1;
            end
        end

        if (tx_active && !tx_busy && !tx_done && !tx_start) begin
            tx_data  <= score_tx_byte(tx_idx, score_tx_bcd);
            tx_start <= 1'b1;
        end
    end
end

tetris_core u_tetris_core (
    .clk          (clk),
    .rst_n        (rst_n),
    .difficulty   (difficulty),
    .key_rotate   (key_pulse[0]),
    .key_left     (key_pulse[1]),
    .key_right    (key_pulse[2]),
    .key_drop     (key_pulse[3]),
    .key_start    (key_pulse[4]),
    .game_state   (game_state),
    .score        (),
    .score_bcd    (score_bcd),
    .score_changed(score_changed),
    .pixel_index  (pixel_index),
    .pixel_rgb    (pixel_rgb)
);

seven_seg_score u_seven_seg_score (
    .clk        (clk),
    .rst_n      (rst_n),
    .difficulty (difficulty),
    .score_bcd  (score_bcd),
    .blink_score(game_state == 2'd3),
    .sel        (sel),
    .seg        (seg)
);

ws2812_matrix u_ws2812_matrix (
    .clk       (clk),
    .rst_n     (rst_n),
    .pixel_index(pixel_index),
    .pixel_rgb (pixel_rgb),
    .dq        (dq)
);

music u_music (
    .clk   (clk),
    .rst_n (rst_n && (game_state == 2'd1)),
    .buzzer(music_buzzer)
);

uart_tx_byte u_score_uart_tx (
    .clk     (clk),
    .rst_n   (rst_n),
    .tx_start(tx_start),
    .tx_data (tx_data),
    .uart_txd(uart_txd),
    .tx_busy (tx_busy),
    .tx_done (tx_done)
);

assign buzzer = (game_state == 2'd1) ? music_buzzer : 1'b0;

function [7:0] score_tx_byte;
    input [3:0] idx;
    input [19:0] score;
    begin
        case (idx)
            4'd0: score_tx_byte = 8'h53; // S
            4'd1: score_tx_byte = 8'h3a; // :
            4'd2: score_tx_byte = 8'h30 + score[19:16];
            4'd3: score_tx_byte = 8'h30 + score[15:12];
            4'd4: score_tx_byte = 8'h30 + score[11:8];
            4'd5: score_tx_byte = 8'h30 + score[7:4];
            4'd6: score_tx_byte = 8'h30 + score[3:0];
            4'd7: score_tx_byte = 8'h0d;
            4'd8: score_tx_byte = 8'h0a;
            default: score_tx_byte = 8'h0a;
        endcase
    end
endfunction

endmodule
