module breathing_light (
    input           clk,
    input           rst,
    output reg[3:0] led
);

parameter TIMER_1us = 49,
          TIMER_1ms = 999,
          TIMER_1s = 999;
reg [5:0] cnt_1us;
wire      add_cnt_1us, //开始计数标志
          end_cnt_1us;//结束计数标志
reg [9:0] cnt_1ms;
wire      add_cnt_1ms, //开始计数标志
          end_cnt_1ms;//结束计数标志
reg [9:0] cnt_1s;
wire      add_cnt_1s, //开始计数标志
          end_cnt_1s;//结束计数标志
reg on_off_flag;
//1us计数器
always @(posedge clk or negedge rst) begin
    if (!rst)
        cnt_1us <= 0;
    else if (add_cnt_1us) begin
        if(end_cnt_1us)
            cnt_1us <= 0;
        else
            cnt_1us <= cnt_1us + 1;
    end
end
assign add_cnt_1us = 1;
assign end_cnt_1us = add_cnt_1us && cnt_1us == TIMER_1us;

//1ms计数器
always @(posedge clk or negedge rst) begin
    if (!rst)
        cnt_1ms <= 0;
    else if (add_cnt_1ms) begin
        if(end_cnt_1ms)
            cnt_1ms <= 0;
        else
            cnt_1ms <= cnt_1ms + 1;
    end
end
assign add_cnt_1ms = end_cnt_1us;//串在一起
assign end_cnt_1ms = add_cnt_1ms && cnt_1ms == TIMER_1ms;

always @(posedge clk or negedge rst) begin
    if (!rst)
        cnt_1s <= 0;
    else if (add_cnt_1s) begin
        if(end_cnt_1s) begin
            cnt_1s <=0;
        end
        else
            cnt_1s <= cnt_1s+1;
    end
end
assign add_cnt_1s = end_cnt_1ms;
assign end_cnt_1s = add_cnt_1s && cnt_1s == TIMER_1s;

//区分从灭到亮
always @(posedge clk or negedge rst) begin
    if (!rst)
        on_off_flag <=0;
    else if (cnt_1us == 49 && cnt_1ms == 999 && cnt_1s == 999) begin
        on_off_flag <= ~on_off_flag;
    end
end

//output
always @(posedge clk or negedge rst) begin
    if (!rst)
     led<= 4'b0000;
    else if ((on_off_flag == 0 && cnt_1s >= cnt_1ms) || (on_off_flag == 1 && cnt_1s <= cnt_1ms)) begin
        led <= 4'b1111;
    end
    else
        led <= 4'b0000;
end    


endmodule