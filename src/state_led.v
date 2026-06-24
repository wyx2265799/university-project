module state_led (
    input clk,
    input rst,
    output reg [3:0] led
);
parameter TIME_4s    = 199_999_999;
parameter TIME_500ms = 24_999_999;
parameter HORSE_LED  = 3'b001;
parameter WATER_LED  = 3'b010;
parameter FLASH_LED  = 3'b100;

reg [27:0] cnt_state;//4stimer
reg [24:0] cnt_led  ;//0.5s
reg [2:0]  c_state  ;//当前状态
reg [2:0]  n_state  ;//未来状态
reg [3:0] horse_led ;
reg [3:0] water_led ;
reg [3:0] flash_led ;
always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt_state <= 0;
    else if(cnt_state == TIME_4s)
        cnt_state <= 0;
    else
    cnt_state <= cnt_state +1;

end

//0.5s
always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt_led <= 0;
    else if (cnt_led == TIME_500ms)
        cnt_led <= 0;
    else
        cnt_led <= cnt_led +1;
end
    
always @(posedge clk or negedge rst) begin
    if(!rst)
        c_state <= HORSE_LED;
    else
        c_state <= n_state;
end

//状态跳转
always @(*) begin
    case (c_state)
        HORSE_LED:n_state = (cnt_state == TIME_4s) ? WATER_LED : HORSE_LED;
        WATER_LED:n_state = (cnt_state == TIME_4s) ? FLASH_LED : WATER_LED;
        FLASH_LED:n_state = (cnt_state == TIME_4s) ? HORSE_LED : FLASH_LED;
        default: n_state = HORSE_LED;
    endcase
end
//给三个寄存灯赋值
always @(posedge clk or negedge rst) begin
    if (rst == 0) begin
        horse_led <= 4'b0001;
        water_led <= 4'b0001;
        flash_led <= 4'b1111;
    end
    else
        case (c_state)
            HORSE_LED:
                if(cnt_led == TIME_500ms)
                    horse_led <= {horse_led[2:0], horse_led[3]};
            WATER_LED: 
                if(cnt_led == TIME_500ms) 
                    water_led <= {water_led[2:0], ~water_led[3]};
            FLASH_LED:flash_led <= (cnt_led == TIME_500ms) ? ~flash_led:flash_led;
            default: begin
                horse_led <= 4'b0001;
                water_led <= 4'b0001;
                flash_led <= 4'b1111;
            end
        endcase
end
//输出
always @(*) begin
    case (c_state)
        HORSE_LED: led = horse_led;
        WATER_LED: led = water_led;
        FLASH_LED: led = flash_led;
        default: led = horse_led;
    endcase
end
endmodule