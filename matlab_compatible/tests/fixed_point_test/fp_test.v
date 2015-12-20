module fp_test #(parameter N=16)
(
	input clk,
	input rst,
	input [N-1:0]a,
	input [N-1:0]b,
	input start,
	output [N-1:0]c,
	output rdy
);

reg state;

always @(posedge rst, posedge clk)
    if(rst)
    begin
        state <= 0;
    end else
        if(~state)
        begin
            if(start)
                state <= 1;
        end else
            begin
                if(rdy)
                    state <= 0;
            end
        

cordic_mult_core #(.N(N))
cordic_mult_core(
	.clk(clk),
	.rst(rst),
	.a(a),
	.b(b),
	.start(start&(~state)),
	.c(c),
	.rdy(rdy)
);
endmodule