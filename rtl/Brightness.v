module Brightness(
input clk,
input rst,
input signed [8:0] R,G,B,
input wire [23:0] pixel,
output reg [23:0] bright
);
wire signed[9:0] sum_r;
wire signed[9:0] sum_g;
wire signed[9:0] sum_b;

assign sum_r = $signed({1'b0, pixel[23:16]}) +  R;
assign sum_g = $signed({1'b0, pixel[15:8]})  +  G;
assign sum_b = $signed({1'b0, pixel[7:0]})   +  B;
always@(posedge clk)begin
if(rst)
bright<=24'd0;
else begin

if (sum_r<0)
    bright[23:16] <= 0;
else if(sum_r>=255)
   bright[23:16]<= 255;
else
   bright[23:16]<=sum_r[7:0];

if (sum_g<0)
    bright[15:8] <= 0;
else if(sum_g>=255)
   bright[15:8]<= 255;
else
   bright[15:8]<= sum_g[7:0];
   
   
if (sum_b<0)
    bright[7:0] <= 0;
else if(sum_b>=255)
   bright[7:0]<= 255;
else
   bright[7:0]<= sum_b[7:0];
   
end
end
endmodule