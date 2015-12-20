module no_clock_model(
    input [7:0]in_8bit,
    input [23:0]in_24bit,
    input [63:0]in_64bit,
    input [95:0]in_96bit,
    input [7:0]in_mem_8bit[0:9],
    input [63:0]in_mem_64bit[0:9],
    input [77:0]in_mem_78bit[0:9],
    output [23:0]out_24bit,
    output [63:0]out_64bit,
    output [95:0]out_96bit,
    output reg [7:0]out_mem_8bit[0:9],
    output reg [77:0]out_mem_78bit[0:9]
//InOut signals in module interface are not supported by vmodel
);

assign out_96bit = {in_64bit,in_24bit,in_8bit}+{32'b0,in_64bit};
assign out_64bit = ~in_64bit;
assign out_24bit = {in_8bit,in_8bit,in_8bit} - in_24bit;

wire hidden_var/*verilator public*/;
assign hidden_var=~in_8bit[0];

reg [1:0]hidden_mem[0:9] /*verilator public*/;
reg [7:0]hidden_mem_data;
reg [100:0]huge_hidden_mem[0:5] /*verilator public*/;

integer i;

always @(*)
    begin
        for (i=0; i<10; i=i+1)
        begin
            out_mem_8bit[i]=in_mem_8bit[i]+1;
            out_mem_78bit[i]=in_mem_78bit[9-i];
            hidden_mem_data=in_mem_8bit[i];
            hidden_mem[i]=hidden_mem_data[1:0];
        end
        for (i=0; i<6; i=i+1)
        begin
            huge_hidden_mem[i]=0;
        end
    end

endmodule