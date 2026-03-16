module grayscale(
    input clk,
    input rst,
    input pixel_valid,
    input wire [23:0] pixel,
    output reg [23:0] gray
);

reg [7:0] y;

always @(posedge clk) begin
    if (rst) begin
        gray <= 24'd0;
        y    <= 8'd0;
    end else if (pixel_valid) begin  // FIXED: gate on pixel_valid
        y    <= (pixel[23:16] * 8'd77 +
                 pixel[15:8]  * 8'd150 +
                 pixel[7:0]   * 8'd29) >> 8;
        gray <= {y, y, y};
    end
end


