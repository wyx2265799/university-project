module ws2812_love (
    input       clk,
    input       rst,
    output reg  dq
);
    
parameter TIME = 14999;//300us的复位帧
reg [5:0]   cnt_0;//一个bit持续时间
wire add_cnt_0, end_cnt_0;
reg [4:0]   cnt_1;//一个等有24个bit
wire add_cnt_1,end_cnt_1;
reg [5:0] cnt_2;//点阵有64个灯
wire add_cnt_2, end_cnt_2;
reg [13:0]  cnt_3;//复位帧计数器
wire add_cnt_3, end_cnt_3;
reg flag;//0:正常显示；1：复位
//生成64个24位的二维数组
reg [23:0] reg_data[63:0];
reg [23:0] data;
//初始化爱心图像
initial begin   
    reg_data[0]  = 24'h000000;reg_data[1]  = 24'h000000;reg_data[2]  = 24'h000000;reg_data[3]  = 24'h000000;reg_data[4]  = 24'h000000;reg_data[5]  = 24'h000000;reg_data[6]  = 24'h000000;reg_data[7]  = 24'h000000;
    reg_data[8]  = 24'h000000;reg_data[9]  = 24'h000700;reg_data[10] = 24'h000700;reg_data[11] = 24'h000000;reg_data[12] = 24'h000000;reg_data[13] = 24'h000700;reg_data[14] = 24'h000700;reg_data[15] = 24'h000000;
    reg_data[16] = 24'h000700;reg_data[17] = 24'h000700;reg_data[18] = 24'h000700;reg_data[19] = 24'h000700;reg_data[20] = 24'h000700;reg_data[21] = 24'h000700;reg_data[22] = 24'h000700;reg_data[23] = 24'h000700;
    reg_data[24] = 24'h000700;reg_data[25] = 24'h000700;reg_data[26] = 24'h000700;reg_data[27] = 24'h000700;reg_data[28] = 24'h000700;reg_data[29] = 24'h000700;reg_data[30] = 24'h000700;reg_data[31] = 24'h000700;
    reg_data[32] = 24'h000000;reg_data[33] = 24'h000700;reg_data[34] = 24'h000700;reg_data[35] = 24'h000700;reg_data[36] = 24'h000700;reg_data[37] = 24'h000700;reg_data[38] = 24'h000700;reg_data[39] = 24'h000000;
    reg_data[40] = 24'h000000;reg_data[41] = 24'h000000;reg_data[42] = 24'h000700;reg_data[43] = 24'h000700;reg_data[44] = 24'h000700;reg_data[45] = 24'h000700;reg_data[46] = 24'h000000;reg_data[47] = 24'h000000;
    reg_data[48] = 24'h000000;reg_data[49] = 24'h000000;reg_data[50] = 24'h000000;reg_data[51] = 24'h000700;reg_data[52] = 24'h000700;reg_data[53] = 24'h000000;reg_data[54] = 24'h000000;reg_data[55] = 24'h000000;
    reg_data[56] = 24'h000000;reg_data[57] = 24'h000000;reg_data[58] = 24'h000000;reg_data[59] = 24'h000000;reg_data[60] = 24'h000000;reg_data[61] = 24'h000000;reg_data[62] = 24'h000000;reg_data[63] = 24'h000000;
end
//比特计数器1bit持续时间
always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt_0<=0;
    else if (add_cnt_0) begin
        if(end_cnt_0)
            cnt_0<= 0;
        else
            cnt_0 = cnt_0+1;
    end
    
end
assign add_cnt_0 = flag;     
assign end_cnt_0 = add_cnt_0 && cnt_0 == 63;
//一个灯24个bit
always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt_1<=0;
    else if (add_cnt_1) begin
        if(end_cnt_1)
            cnt_1<= 0;
        else
            cnt_1 = cnt_1+1;
    end
    
end
assign add_cnt_1 = end_cnt_0;
assign end_cnt_1 = add_cnt_1 && cnt_1 == 23;
//一个点阵64个灯
always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt_2<=0;
    else if (add_cnt_2) begin
        if(end_cnt_2)
            cnt_2<= 0;
        else
            cnt_2 = cnt_2+1;
    end
    
end
assign add_cnt_2 = end_cnt_1;
assign end_cnt_2 = add_cnt_2 && cnt_2 == 63;
//0:正常显示；1：复位
always @(posedge clk or negedge rst) 
    if(!rst)
        flag<=1;
    else if(end_cnt_2)
        flag<=0;
    else if (end_cnt_3)
        flag<=1;

//复位帧计数器
always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt_3<=0;
    else if (add_cnt_3) begin
        if(end_cnt_3)
            cnt_3<= 0;
        else
            cnt_3 = cnt_3+1;
    end
    
end
assign add_cnt_3 = flag == 0;
assign end_cnt_3 = add_cnt_3 && cnt_3 == TIME;

//寄存从reg_data数组里索引出来的数据
always @(posedge clk or negedge rst) begin
    if(!rst)
        data<=0;
    else    data<=reg_data[cnt_2];
end
//输出
always @(posedge clk or negedge rst) begin
    if(!rst)
        dq<=0;
    //发送0码
    else if(data[23 - cnt_1] == 0 && flag)
        if(cnt_0<18)
            dq<=1;
        else    
            dq<=0;
    //发送1码
    else if(data[23-cnt_1]==1 && flag)
        if(cnt_0<32)
            dq<=1;
        else
            dq<=0;
end
endmodule


