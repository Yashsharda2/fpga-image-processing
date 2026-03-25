module cam_rx (
    input                         clk,
    input                         data_queue_empty,
    input                         data_queue_almost_empty,
    output reg                    request_data = 0,
    input  [RAH_PACKET_WIDTH-1:0] data_frame,

    output reg [23:0]             pixel = 0,
    output reg                    pixel_valid = 0
);

parameter RAH_PACKET_WIDTH = 48;

reg [1:0] state = 0;

always @(posedge clk) begin
    pixel_valid <= 0;
    case (state)
        0: begin
            if (~data_queue_empty) begin
                request_data <= 1;
                state <= 1;
            end
        end
        1: begin
            request_data <= 0;
            state <= 2;
        end
        2: begin
            pixel       <= data_frame[23:0];
            pixel_valid <= 1;
            state <= 0;
        end
    endcase
end

endmodule