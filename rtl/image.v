module image (
    input wire clk,
    input wire rst,
    output  [23:0] pixel_out
);

(* keep *) wire [23:0] pixel_out;

    reg [8:0]  x;        // 0 → 399
    reg [8:0]  y;        // 0 → 265
    reg [16:0] addr;     // 17-bit address
reg frame_start;
reg pixel_valid;
    wire [23:0] pixel;

    always @(posedge clk) begin
    if(rst)begin
    x<=0;
    y<=0;
    addr<=0;
    frame_start<=1'b1;
    pixel_valid<=1'b0;
    end else begin
    frame_start<=1'b0;
    pixel_valid<=1'b1;
    if(x==0 && y==0)
        frame_start<=1'b1;
        if (x == 399) begin
            x <= 0;
            if (y == 265)
                y <= 0;
            else
                y <= y + 1;
        end else begin
            x <= x + 1;
        end

        addr <= y * 400 + x;
    end
end

    image_rom u_image_rom (
        .clk   (clk),
        .addr  (addr),
        .pixel (pixel)
    );

    grayscale o_gray(
       .clk(clk),
       .rst(rst),
       .pixel(pixel),
       .gray(pixel_out)
     );
endmodule
