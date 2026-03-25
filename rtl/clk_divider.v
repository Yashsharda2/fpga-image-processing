module clk_divider (
    input  clk150,
    input  rst,
    output clk75,
    output clk50_a,
    output clk50_b
);

reg clk75_r   = 0;
reg clk50_a_r = 0;
reg clk50_b_r = 0;
reg [1:0] cnt3 = 0;

// ÷2 → 75 MHz
always @(posedge clk150) begin
    if (rst) clk75_r <= 0;
    else     clk75_r <= ~clk75_r;
end

// ÷3 → 50 MHz
always @(posedge clk150) begin
    if (rst) begin
        cnt3    <= 0;
        clk50_a_r <= 0;
        clk50_b_r <= 0;
    end else begin
        if (cnt3 == 2) begin
            cnt3      <= 0;
            clk50_a_r <= ~clk50_a_r;
            clk50_b_r <= ~clk50_b_r;
        end else begin
            cnt3 <= cnt3 + 1;
        end
    end
end

// Route through GLOBAL buffers so Efinity uses clock spine
// not fabric routing — this removes the ~FF|Q suffix
EFX_GBUFCE buf_vga  (.I(clk75_r),   .CE(1'b1), .O(clk75));
EFX_GBUFCE buf_rx   (.I(clk50_a_r), .CE(1'b1), .O(clk50_a));
EFX_GBUFCE buf_tx   (.I(clk50_b_r), .CE(1'b1), .O(clk50_b));

endmodule