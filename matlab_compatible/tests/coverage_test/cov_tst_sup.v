module cov_tst_sup(
    input [7:0]in,
    output out
);

assign out = (in==167) ? 0 : 1;

endmodule