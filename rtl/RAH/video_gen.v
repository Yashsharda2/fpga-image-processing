/* generate video for the MIPI transfer*/
module video_gen (
    input               rst,
    input               clk,
    output              video_hsync_o,
    output              video_hsync_o_2,
    output              video_vsync_o,
    output              video_valid_h_o,
    output              pre_video_valid_h_o,
    output              video_valid_h_o_2,
    output              video_valid_v_o,
    output              valid_frame,
    output reg [15:0]   x,
    output reg [15:0]   y
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
BsWcmDvtHwjr0rmB5SVmdE6AVQVutsw/9cS8FnSZegczkaeBRNwtu8vEOdo7N690
tYmxZ8rV6zh/+xQFie2ULeYBDpOOIrZpHKyYWlaDe0ah/ZICZkmEloshQYYYk68W
+LkKpXBy34M4kUcuo69OvuAM4rRusJGd7CWCrSrPIpcwVVpJp9NN3Og2khFWRxdT
76hDqNxjgFweGBYLS9VfAPoc/2N0wPhCBGkXcwtN568XS9O/Fj0ENhFpQ/v3GFEb
N7eQmGmuogX89Xixzx5aQZelHq0pmwy0BMpOOi8EKR6+yHIPOiFyBGjDJUp7r17H
nbaQyPUQzMVIyJWj2Jv4Lg==

`pragma protect key_keyowner="Mentor Graphics Corporation"
`pragma protect key_keyname="MGC-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
dzkhWEcmVv7Npf/0mJmYz6HZUsFGK/U4tOJwyU8YGi9sWb+1ZlzvD0Oz0ZGLGVGv
ba7/+OilM2iSFVZUtnAuWGZrFa806bw3/tYu7PaWE93NHSEK6bgFPWzl38r4Lwc/
5FOUVKtGXkjzJKRbgE7tjgHdBmL7DqrUpxnzFOh8NUU=


`pragma protect data_method="aes256-cbc"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=2947)
`pragma protect data_block
+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
`pragma protect end_protected

endmodule
