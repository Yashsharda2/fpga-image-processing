module rah_decoder (
    /* rah raw input variables */
    input                                   clk,

    input [DATA_WIDTH-1:0]                  mipi_data,
    input                                   mipi_rx_valid,

    /* apps i/o definition */
    input [TOTAL_APPS-1:0]                  rd_clk,
    input [TOTAL_APPS-1:0]                  request_data,

    output reg                              end_of_packet = 0,
    output [TOTAL_APPS-1:0]                 data_queue_empty,
    output [TOTAL_APPS-1:0]                 data_queue_almost_empty,
    output [(TOTAL_APPS*DATA_WIDTH)-1:0]    rd_data,
    output [TOTAL_APPS-1:0]                 error
);

`pragma protect begin_protected
`pragma protect version=1
`pragma protect encrypt_agent="ipecrypt"
`pragma protect encrypt_agent_info="IP Encrypter LLC, http://ipencrypter.com, Version: 23.7.0"
`pragma protect author="Vicharak"
`pragma protect author_info="Vicharak Computers Pvt Ltd"

`pragma protect key_keyowner="Efinix Inc."
`pragma protect key_keyname="EFX_K01"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=256)
`pragma protect key_block
WpsdjgCWN6dBEypj2v1B3WeEFTrTyHIPV0xI9Xh9h0LGTLisxxQBui+852GWVKeP
dozxCTLItotjpRS5sZcfuA/2TFtfFAmQup3bGh+R27flBOQjFV1dvsnOao4F2QKo
fVqpIz3pZa9wDBRhcQ5jUOlCMzp5yUCVVT0APrn+DuQUYgmgKg1wpkp7Uc/YLW23
+RQ1XnEWmccuK5DLpub4YsL/V1Mz0iAK/BJgwtpiaI68LWQrfr6cMd7ijboCWcA9
SvwOfzJZA9OseoT9fES4xERHkSHxq+bkEk8qLscOtBgx+m7PFepNBSYfhNAc0e3x
0nbcfjITEILTSQoURZ6OPA==

`pragma protect key_keyowner="Mentor Graphics Corporation"
`pragma protect key_keyname="MGC-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
lfAJfzzjwma+KYdApCcp89lCi3ouYLyQgEX8tl7MOvD0zDGassww5rtwy029gt+A
eZ2CEVXmOu6yCJ115uBmzLueOheRuQgKXKJOSdYL2iDo1TjUdxa0J7epKgccKvyr
QeiRZIcWhnASNkGTG3wDl23ZpdK/niBik9WYe19BnIU=


`pragma protect data_method="aes256-cbc"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=3329)
`pragma protect data_block
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
`pragma protect end_protected

endmodule
