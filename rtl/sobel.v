module sobel(
    input clk,
    input rst,
    input pixel_valid,
    input wire [23:0] pixel,
    output reg [23:0] edge_out
);

reg [7:0] line_buf1 [0:399];  // row N-1
reg [7:0] line_buf2 [0:399];  // row N-2

reg signed [10:0] Gx, Gy;
reg [8:0] col;

reg [8:0] col_d1;

reg [7:0] cur0, cur1, cur2;

wire [7:0] y = (pixel[23:16] * 8'd77 +
                pixel[15:8]  * 8'd150 +
                pixel[7:0]   * 8'd29) >> 8;

reg [19:0] pix_count;

always @(posedge clk) begin
    if (rst)
        pix_count <= 0;
    else if (pixel_valid)
        pix_count <= pix_count + 1;
end

wire window_valid = (pix_count >= 802);

always @(posedge clk) begin
    if (pixel_valid) begin
        line_buf2[col] <= line_buf1[col];
        line_buf1[col] <= y;
    end
end

always @(posedge clk) begin
    if (rst)
        col <= 0;
    else if (pixel_valid) begin
        if (col == 399)
            col <= 0;
        else
            col <= col + 1;
    end
end


always @(posedge clk) begin
    if (pixel_valid)
        col_d1 <= col;
end


always @(posedge clk) begin
    if (rst) begin
        cur0 <= 0;
        cur1 <= 0;
        cur2 <= 0;
    end else if (pixel_valid) begin
        cur2 <= cur1;
        cur1 <= cur0;
        cur0 <= y;
    end
end


always @(posedge clk) begin
    if (!window_valid) begin
        Gx <= 0;
        Gy <= 0;
    end else begin
        Gx <= ($signed({1'b0, line_buf2[col_d1+1]}) + 2*$signed({1'b0, line_buf1[col_d1+1]}) + $signed({1'b0, cur0}))
            - ($signed({1'b0, line_buf2[col_d1-1]}) + 2*$signed({1'b0, line_buf1[col_d1-1]}) + $signed({1'b0, cur2}));

        Gy <= ($signed({1'b0, cur2}) + 2*$signed({1'b0, cur1}) + $signed({1'b0, cur0}))
            - ($signed({1'b0, line_buf2[col_d1-1]}) + 2*$signed({1'b0, line_buf2[col_d1]}) + $signed({1'b0, line_buf2[col_d1+1]}));
    end
end

wire [11:0] G = (Gx[10] ? -Gx : Gx) + (Gy[10] ? -Gy : Gy);

always @(posedge clk) begin
    if (!window_valid)
        edge_out <= 24'd0;
    else begin
        if (G > 255)
            edge_out <= 24'hFFFFFF;
        else
            edge_out <= {G[7:0], G[7:0], G[7:0]};
    end
end

endmodule