%%*********************vmodel MATLAB Verilog simulator******************
%%Moscow, Control Problems Department MIREA, 2009-2015
%%Authors: Romanov A
%%
%%Distributed under the GNU LGPL
%%**********************************************************************

function [ out] = rmrows( inp,i )
%RMROWS works the same way as removerows, but can work with
%structure vectors in matlab versions 2011 or older

len=size(inp,1);
if (i>len)||(i<1)
    out=inp;
    return
end

if (len==1)
    out=[];
    return
end

if (i==len)
    out=inp(1:end-1);
    return
end

if (i==1)
    out=inp(2:end);
    return
end

out=[inp(1:i-1); inp(i+1:end)];

end

