module grayscale(     // Grayscale
input clk,
input rst,
input wire [23:0] pixel,
output reg [23:0] gray
);
 (* keep *) wire [23:0] pixel;

reg [7:0] y;
  always@(posedge clk)begin
  if(rst)
  gray<=24'd0;
  else begin
  y<= (pixel [23:16] * 8'd77 +
       pixel [15:8] * 8'd150 + 
       pixel [7:0] * 8'd29) >>8; 
  
  gray <= {y,y,y};
  end
  end
  endmodule
