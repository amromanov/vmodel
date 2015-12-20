module parameter_model(
    input a,
    input b,
    output c
);

inst_model inst(
     .a(a),
     .b(b),
     .c(c)
    );

endmodule


module inst_model(
    input a,
    input b,
    output c
);

xor_op xop(
        .x(a),
        .y(b),
        .z(c)
    );

endmodule