`include "rah_var_defs.vh"

module image (
    input                       rx_pixel_clk,
    input                       tx_pixel_clk,
    input                       tx_vga_clk,

    input                       my_mipi_rx_VALID,
    input [3:0]                 my_mipi_rx_HSYNC,
    input [3:0]                 my_mipi_rx_VSYNC,
    input [63:0]                my_mipi_rx_DATA,
    input [5:0]                 my_mipi_rx_TYPE,
    input [1:0]                 my_mipi_rx_VC,
    input [3:0]                 my_mipi_rx_CNT,
    input [17:0]                my_mipi_rx_ERROR,
    input                       my_mipi_rx_ULPS_CLK,
    input [3:0]                 my_mipi_rx_ULPS,

    output                      my_mipi_rx_DPHY_RSTN,
    output                      my_mipi_rx_RSTN,
    output                      my_mipi_rx_CLEAR,
    output [1:0]                my_mipi_rx_LANES,
    output [3:0]                my_mipi_rx_VC_ENA,

    output                      my_mipi_tx_DPHY_RSTN,
    output                      my_mipi_tx_RSTN,
    output                      my_mipi_tx_VALID,
    output                      my_mipi_tx_HSYNC,
    output                      my_mipi_tx_VSYNC,
    output [63:0]               my_mipi_tx_DATA,
    output [5:0]                my_mipi_tx_TYPE,
    output [1:0]                my_mipi_tx_LANES,
    output                      my_mipi_tx_FRAME_MODE,
    output [15:0]               my_mipi_tx_HRES,
    output [1:0]                my_mipi_tx_VC,
    output [3:0]                my_mipi_tx_ULPS_ENTER,
    output [3:0]                my_mipi_tx_ULPS_EXIT,
    output                      my_mipi_tx_ULPS_CLK_ENTER,
    output                      my_mipi_tx_ULPS_CLK_EXIT,

    input  [2:0]                mode       // 00=grayscale 01=brightness 10=threshold
  
);

parameter RAH_PACKET_WIDTH  = 48;
parameter ACTIVE_VID_WIDTH  = 400;
parameter ACTIVE_VID_HEIGHT = 266;
parameter TOTAL_APPS        = `TOTAL_APPS + 1;  // = 2

/* Fixed internal values — make ports later when needed */
wire        rst      = 1'b0;
wire signed [8:0] bright_R = 9'd20;
wire signed [8:0] bright_G = 9'd20;
wire signed [8:0] bright_B = 9'd20;
wire [7:0]  thresh_T = 8'd128;

/* MIPI RX config */
assign my_mipi_rx_DPHY_RSTN = 1'b1;
assign my_mipi_rx_RSTN      = 1'b1;
assign my_mipi_rx_CLEAR     = 1'b0;
assign my_mipi_rx_LANES     = 2'b11;
assign my_mipi_rx_VC_ENA    = 4'b0001;

/* RAH decoder wires */
wire [TOTAL_APPS-1:0]                    rd_clk;
wire [TOTAL_APPS-1:0]                    request_data;
wire [TOTAL_APPS-1:0]                    data_queue_empty;
wire [TOTAL_APPS-1:0]                    data_queue_almost_empty;
wire [TOTAL_APPS-1:0]                    rd_error;
wire [(TOTAL_APPS*RAH_PACKET_WIDTH)-1:0] rd_data;
wire [RAH_PACKET_WIDTH-1:0]              aligned_data;
wire                                     end_of_packet;

/* RAH encoder wires */
wire [TOTAL_APPS-1:0]                    wr_clk;
wire [(TOTAL_APPS*RAH_PACKET_WIDTH)-1:0] wr_data;
wire [TOTAL_APPS-1:0]                    write_apps_data;
wire [TOTAL_APPS-1:0]                    wr_fifo_full;
wire [TOTAL_APPS-1:0]                    wr_almost_fifo_full;
wire [TOTAL_APPS-1:0]                    wr_prog_fifo_full;

/* data_aligner */
data_aligner #(.DATA_WIDTH(RAH_PACKET_WIDTH)) da (
    .clk           (rx_pixel_clk),
    .mipi_data     (my_mipi_rx_DATA),
    .end_of_packet (end_of_packet),
    .rx_valid      (my_mipi_rx_VALID),
    .aligned_data  (aligned_data)
);

/* rah_decoder */
rah_decoder #(.TOTAL_APPS(TOTAL_APPS), .DATA_WIDTH(RAH_PACKET_WIDTH)) rd (
    .clk                     (rx_pixel_clk),
    .mipi_data               (aligned_data),
    .mipi_rx_valid           (my_mipi_rx_VALID),
    .rd_clk                  (rd_clk),
    .request_data            (request_data),
    .end_of_packet           (end_of_packet),
    .data_queue_empty        (data_queue_empty),
    .data_queue_almost_empty (data_queue_almost_empty),
    .rd_data                 (rd_data),
    .error                   (rd_error)
);

/* App0: version check — always required, do not remove */
assign rd_clk[0] = rx_pixel_clk;
assign wr_clk[0] = rx_pixel_clk;

rah_version_check #(.RAH_PACKET_WIDTH(RAH_PACKET_WIDTH)) rvc (
    .clk          (rx_pixel_clk),
    .in_data      (`GET_DATA_RAH(0)),
    .q_empty      (data_queue_empty[0]),
    .request_data (request_data[0]),
    .w_en         (write_apps_data[0]),
    .out_data     (`SET_DATA_RAH(0))
);

/* App1: cam_rx — receives pixels from SoC, fans out to processing */
assign rd_clk[`CAM_RX] = rx_pixel_clk;
assign wr_clk[`CAM_RX] = rx_pixel_clk;

wire [23:0] pixel;
wire        pixel_valid;

cam_rx #(.RAH_PACKET_WIDTH(RAH_PACKET_WIDTH)) cam (
    .clk                     (rx_pixel_clk),
    .data_queue_empty        (data_queue_empty[`CAM_RX]),
    .data_queue_almost_empty (data_queue_almost_empty[`CAM_RX]),
    .request_data            (request_data[`CAM_RX]),
    .data_frame              (`GET_DATA_RAH(`CAM_RX)),
    .pixel                   (pixel),
    .pixel_valid             (pixel_valid)
);

/* Send processed result back to SoC */
assign write_apps_data[`CAM_RX] = pixel_valid;
assign wr_data[(`CAM_RX * RAH_PACKET_WIDTH) +: RAH_PACKET_WIDTH] = 
       {{(RAH_PACKET_WIDTH-24){1'b0}}, processed_pixel};

/* Processing modules */
wire [23:0] gray_out;
wire [23:0] bright_out;
wire [23:0] thresh_out;
wire [23:0] sobel_out;

grayscale gs (
    .clk   (rx_pixel_clk),
    .rst   (rst),
    .pixel (pixel),
    .gray  (gray_out)
);

Brightness br (
    .clk   (rx_pixel_clk),
    .rst   (rst),
    .R     (bright_R),
    .G     (bright_G),
    .B     (bright_B),
    .pixel (pixel),
    .bright(bright_out)
);

threshold th (
    .clk   (rx_pixel_clk),
    .rst   (rst),
    .T     (thresh_T),
    .pixel (pixel),
    .b_w   (thresh_out)
);

sobel sb (
    .clk          (rx_pixel_clk),
    .rst          (rst),
    .pixel_valid  (pixel_valid),
    .pixel        (pixel),
    .edge_out     (sobel_out)
);

/* Mode select */
reg [23:0] processed_pixel;
always @(posedge rx_pixel_clk) begin
    case (mode)
        3'b000: processed_pixel <= gray_out;
        3'b001: processed_pixel <= bright_out;
        3'b010: processed_pixel <= thresh_out;
        3'b011: processed_pixel <= sobel_out;
        default: processed_pixel <= gray_out;
    endcase
end



/* rah_encoder */
wire vid_gen_clk;
assign vid_gen_clk = tx_vga_clk;
wire mipi_out_rst, mipi_valid;
wire [RAH_PACKET_WIDTH-1:0] mipi_out_data;
wire hsync, vsync;

rah_encoder #(
    .TOTAL_APPS(TOTAL_APPS),
    .WIDTH     (ACTIVE_VID_WIDTH),
    .HEIGHT    (ACTIVE_VID_HEIGHT),
    .DATA_WIDTH(RAH_PACKET_WIDTH)
) re (
    .clk                 (tx_pixel_clk),
    .vid_gen_clk         (vid_gen_clk),
    .send_data           (write_apps_data),
    .wr_clk              (wr_clk),
    .wr_data             (wr_data),
    .wr_fifo_full        (wr_fifo_full),
    .wr_almost_fifo_full (wr_almost_fifo_full),
    .wr_prog_fifo_full   (wr_prog_fifo_full),
    .mipi_rst            (mipi_out_rst),
    .mipi_valid          (mipi_valid),
    .mipi_data           (mipi_out_data),
    .hsync_patgen        (hsync),
    .vsync_patgen        (vsync)
);

/* MIPI TX outputs */
assign my_mipi_tx_DPHY_RSTN      = ~mipi_out_rst;
assign my_mipi_tx_RSTN           = ~mipi_out_rst;
assign my_mipi_tx_VALID          = mipi_valid;
assign my_mipi_tx_HSYNC          = hsync;
assign my_mipi_tx_VSYNC          = vsync;
assign my_mipi_tx_DATA           = mipi_out_data;
assign my_mipi_tx_TYPE           = 6'h24;
assign my_mipi_tx_LANES          = 2'b11;
assign my_mipi_tx_FRAME_MODE     = 1'b0;
assign my_mipi_tx_HRES           = ACTIVE_VID_WIDTH;
assign my_mipi_tx_VC             = 2'b00;
assign my_mipi_tx_ULPS_ENTER     = 4'b0000;
assign my_mipi_tx_ULPS_EXIT      = 4'b0000;
assign my_mipi_tx_ULPS_CLK_ENTER = 1'b0;
assign my_mipi_tx_ULPS_CLK_EXIT  = 1'b0;

endmodule