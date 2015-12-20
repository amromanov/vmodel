module cov_tst_main(
    input rst,
    input clk,
    input [7:0]in,
    output reg [7:0]out
);

wire var1;

cov_tst_sup ct_sup(
        .in(in),
        .out(var1)
    );

always @(posedge clk, posedge rst)
    if(rst)
        out <= 0;
    else begin
            if(in[7])
            begin
                if(out>100)
                    out <= in;
                else
                    out <= -in;
            end else
                begin
                    if(in<70)
                        out <= 21;
                end
            out[0] <= var1;
         end

endmodule