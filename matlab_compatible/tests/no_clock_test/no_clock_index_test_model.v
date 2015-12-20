module no_clock_index_test_model(
    input [31:8]_24bit,
    input [100:30]_71bit,
    input [15:8]in_mem_8bit[2:5],
    output [50:10]_41bit_out,
    output reg [7:0]out_mem_8bit[0:9]
);

integer i;

assign _41bit_out={_71bit[74:50],_24bit[31:16]};

always @(*)
    begin
        for (i=0; i<10; i=i+1)
        begin
            out_mem_8bit[i]=100;
            out_mem_8bit[i]=in_mem_8bit[9-i];
        end
    end

endmodule