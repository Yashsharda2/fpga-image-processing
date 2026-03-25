module grayscale(
    input clk,
    input rst,
    input pixel_valid,
    input wire [23:0] pixel,
    output reg [23:0] gray
);

wire [7:0] y_comb;
assign y_comb = (pixel[23:16] * 8'd77 +
                 pixel[15:8]  * 8'd150 +
                 pixel[7:0]   * 8'd29) >> 8;

always @(posedge clk) begin
    if (rst) begin
        gray <= 24'd0;
    end else if (pixel_valid) begin
        gray <= {y_comb, y_comb, y_comb};
    end
end

endmodule