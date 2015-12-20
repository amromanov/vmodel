module simple_test(
    input rst,
    input clk,
    input  [30:0]a,
    input  [30:0]b,
    output reg [31:0]adder_result,
    output [15:0]counter,
    output [96:0]_97bit_round,
    output counter_rdy,
    output clk_echo
);

wire [74:0]hidden_mem[0:99]/*verilator public*/;
wire [74:0]hidden_signal/*verilator public*/;
wire [12:0]short_hidden_signal/*verilator public*/;

assign clk_echo=clk;

reg [30:0]a_s;
reg [30:0]b_s;

always @(posedge clk, posedge rst)
    if(rst)
        {a_s,b_s} <= 0;
    else
        {a_s,b_s} <= {a,b};

always @(posedge clk, posedge rst)
    if(rst)
        adder_result <= 0;
    else
        adder_result <= {a_s[30],a_s} + {b_s[30],b_s};

reg [15:0]cnt;

always @(posedge clk, posedge rst)
    if(rst)
        cnt <= 0;
    else 
        cnt <= cnt + 1;

assign counter_rdy = (cnt==0);

assign counter=cnt;

reg [96:0]shift;

always @(posedge clk, posedge rst)
    if(rst) 
        shift <= 1;
    else
        shift <= {shift[95:0],shift[96]};
    
assign _97bit_round = shift;
endmodule