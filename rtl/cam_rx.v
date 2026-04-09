module cam_rx (
    input                               clk,
    input  [RAH_PACKET_WIDTH-1:0]       a,      
    input                               empty,  
 
    output reg [RAH_PACKET_WIDTH-1:0]   c = 0,  
    output reg                          rden = 0, 
    output reg                          wren = 0 
);
 
parameter RAH_PACKET_WIDTH = 48;
 
localparam IDLE    = 3'd0;
localparam REQ     = 3'd1;
localparam WAIT    = 3'd2;
localparam PROCESS = 3'd3;
localparam WRITE   = 3'd4;
 
reg [2:0] state = IDLE;
reg [23:0] pixel = 0;
 

wire [7:0] gray;
assign gray = (pixel[23:16] * 8'd77 +
               pixel[15:8]  * 8'd150 +
               pixel[7:0]   * 8'd29) >> 8;
 
always @(posedge clk) begin
    case (state)
 
        IDLE: begin
            wren  <= 0;
            rden  <= 0;
            if (~empty) begin
                rden  <= 1;
                state <= REQ;
            end
        end
 
       
        REQ: begin
            rden  <= 0;
            state <= WAIT;
        end
 
        
        WAIT: begin
            pixel <= a[23:0];
            state <= PROCESS;
        end
 
       
        PROCESS: begin
            c     <= {24'h0, gray, gray, gray}; // R=G=B=gray, packed as 24-bit RGB in lower 48
            wren  <= 1;
            state <= WRITE;
        end
 
        WRITE: begin
            wren  <= 0;
            state <= IDLE;
        end
 
    endcase
end
 
endmodule
 