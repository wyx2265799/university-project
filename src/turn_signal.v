module turn_signal (
    input           clk,
    input           rst,
    input  [1:0]    sw_in,//00:all off,  01:turn right  ;10: turn left; 11: both shine     
    output reg[3:0] led
);

parameter TIME = 9_999_999;//200ms
reg [23:0] cnt;
reg [3:0] left_led      ,             //寄存左转向灯
          right_led     ,
          both_shine_led,
          off_led       ;
always @(posedge clk or negedge rst) 
    if (!rst)
        cnt <=0;
    else if (cnt == TIME) begin
        cnt <= 0;
    end
    else
        cnt<= cnt +1;

always @(posedge clk or negedge rst) 
    if (!rst) begin
        left_led      <= 4'b0001;
        right_led     <= 4'b1000;
        both_shine_led<= 4'b1111;
        off_led       <= 4'b0000;
    end
    else 
        case (sw_in)
            2'b00:off_led<=4'b0000;
            2'b01:
                if (cnt == TIME && right_led == 4'b1111)
                    right_led <= 4'b0000;
                else if(cnt == TIME)
                    right_led <= {~right_led[0],right_led[3:1]};   //???
            2'b10:
                if (cnt == TIME && left_led == 4'b1111)
                    left_led <= 4'b0000;
                else if(cnt == TIME)
                    left_led <={left_led[2:0],~left_led[3]};
            2'b11: both_shine_led <= (cnt == TIME) ? ~both_shine_led : both_shine_led;
            default: ;
        endcase
        
always @(posedge clk or negedge rst) 
    if (!rst) 
        led<=4'b0000;
    else
        case (sw_in)
            2'b00:led<=off_led;
            2'b01:led<=right_led;
            2'b10:led<=left_led;
            2'b11:led<=both_shine_led;
            default: ;
        endcase   
endmodule