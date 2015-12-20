module multi_clock_gen_tst(
    input clk,
    input clk10,
    input clk100,
    output out
);

assign out=clk^clk10^clk100;

endmodule