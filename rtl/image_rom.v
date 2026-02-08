module image_rom(
input clk,
input wire [16:0] addr,
output reg [23:0] pixel
);

reg [23:0] image_mem [0:106399]; //row major order

initial begin
$readmemh("image.hex", image_mem);
end

always@(posedge clk)begin
pixel<=image_mem[addr];
end
endmodule
