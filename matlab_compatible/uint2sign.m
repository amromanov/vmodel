function [ out ] = uint2sign( in_arg, N )
%UINT2SIGN Converts N-bit integer from unsigned into signed
%   in_arg - Matrix of input data (integer or float without fractional part)
%   N      - in_arg values bit-width (1..55);
%
%%*********************vmodel MATLAB Verilog simulator******************
%%Moscow, Control Problems Department MIREA, 2009-2015
%%Authors: Romanov A
%%- 
%%Distributed under the GNU LGPL
%%**********************************************************************

out = double(in_arg) - (double(in_arg)>=2^(N-1)).*2^N;

end

