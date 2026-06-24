module uart_message_tx #(
    parameter UART_BPS = 9600,
    parameter CLK_FREQ = 50_000_000
)(
    input        clk,
    input        rst_n,
    input  [1:0] msg_req,
    input  [2:0] difficulty,
    input [19:0] score_bcd,
    output       uart_txd,
    output       busy
);

localparam MSG_NONE    = 2'd0;
localparam MSG_LEVEL   = 2'd1;
localparam MSG_INVALID = 2'd2;
localparam MSG_SCORE   = 2'd3;

reg [1:0]  active_msg;
reg [2:0]  level_latch;
reg [19:0] score_latch;
reg [3:0]  byte_idx;
reg [7:0]  tx_data;
reg        tx_start;

wire tx_busy;
wire tx_done;
wire [3:0] msg_len = message_length(active_msg);
wire send_finished = tx_done && (byte_idx >= msg_len - 1'b1);

assign busy = (active_msg != MSG_NONE) || tx_busy;

uart_tx_byte #(
    .UART_BPS(UART_BPS),
    .CLK_FREQ(CLK_FREQ)
) u_uart_tx_byte (
    .clk     (clk),
    .rst_n   (rst_n),
    .tx_start(tx_start),
    .tx_data (tx_data),
    .uart_txd(uart_txd),
    .tx_busy (tx_busy),
    .tx_done (tx_done)
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        active_msg    <= MSG_NONE;
        level_latch   <= 3'd1;
        score_latch   <= 20'd0;
        byte_idx      <= 4'd0;
        tx_start      <= 1'b0;
        tx_data       <= 8'hff;
    end else begin
        tx_start <= 1'b0;

        if (msg_req != MSG_NONE && active_msg == MSG_NONE && !tx_busy) begin
            active_msg  <= msg_req;
            level_latch <= difficulty;
            score_latch <= score_bcd;
            byte_idx      <= 4'd0;
        end else if (send_finished) begin
            active_msg <= MSG_NONE;
            byte_idx   <= 4'd0;
        end else if (tx_done && active_msg != MSG_NONE) begin
            byte_idx <= byte_idx + 4'd1;
        end

        if (active_msg != MSG_NONE && !tx_busy && !tx_done && !tx_start) begin
            tx_data  <= message_byte(active_msg, byte_idx, level_latch, score_latch);
            tx_start <= 1'b1;
        end
    end
end

function [3:0] message_length;
    input [1:0] msg;
    begin
        case (msg)
            MSG_LEVEL:   message_length = 4'd5;  // D:X\r\n
            MSG_INVALID: message_length = 4'd5;  // ERR\r\n
            MSG_SCORE:   message_length = 4'd9;  // S:xxxxx\r\n
            default:     message_length = 4'd0;
        endcase
    end
endfunction

function [7:0] bcd_ascii;
    input [3:0] digit;
    begin
        bcd_ascii = 8'h30 + digit;
    end
endfunction

function [7:0] message_byte;
    input [1:0] msg;
    input [3:0] idx;
    input [2:0] level;
    input [19:0] score;
    begin
        message_byte = 8'h0a;
        case (msg)
            MSG_LEVEL: begin
                case (idx)
                    4'd0: message_byte = 8'h44; // D
                    4'd1: message_byte = 8'h3a; // :
                    4'd2: message_byte = 8'h30 + level;
                    4'd3: message_byte = 8'h0d;
                    4'd4: message_byte = 8'h0a;
                    default: message_byte = 8'h0a;
                endcase
            end
            MSG_INVALID: begin
                case (idx)
                    4'd0: message_byte = 8'h45; // E
                    4'd1: message_byte = 8'h52; // R
                    4'd2: message_byte = 8'h52; // R
                    4'd3: message_byte = 8'h0d;
                    4'd4: message_byte = 8'h0a;
                    default: message_byte = 8'h0a;
                endcase
            end
            MSG_SCORE: begin
                case (idx)
                    4'd0: message_byte = 8'h53; // S
                    4'd1: message_byte = 8'h3a; // :
                    4'd2: message_byte = bcd_ascii(score[19:16]);
                    4'd3: message_byte = bcd_ascii(score[15:12]);
                    4'd4: message_byte = bcd_ascii(score[11:8]);
                    4'd5: message_byte = bcd_ascii(score[7:4]);
                    4'd6: message_byte = bcd_ascii(score[3:0]);
                    4'd7: message_byte = 8'h0d;
                    4'd8: message_byte = 8'h0a;
                    default: message_byte = 8'h0a;
                endcase
            end
            default: message_byte = 8'h0a;
        endcase
    end
endfunction

endmodule
