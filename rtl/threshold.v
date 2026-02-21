module threshold(    
input clk,
input rst,
input [7:0] T,
input wire [23:0] pixel,
output reg [23:0] b_w
);

wire [9:0] sum_bw;
wire [9:0] thresh;
assign thresh = T * 3;
assign sum_bw = 
    {2'b00, pixel[23:16]} +
    {2'b00, pixel[15:8]} +
    {2'b00, pixel[7:0]};
always@(posedge clk)begin
if(rst)
b_w<=0;
else begin
if(sum_bw>thresh)
b_w<=24'hFFFFFF;
else
b_w <=24'h000000;
end
end
endmodule