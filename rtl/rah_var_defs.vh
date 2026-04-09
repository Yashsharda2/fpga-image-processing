`define TOTAL_APPS 2

`define CAM_RX 1

`define VERSION "1.2.0"

`define GET_DATA_RAH(a) rd_data[a * RAH_PACKET_WIDTH +: RAH_PACKET_WIDTH]
`define SET_DATA_RAH(a) wr_data[a * RAH_PACKET_WIDTH +: RAH_PACKET_WIDTH]