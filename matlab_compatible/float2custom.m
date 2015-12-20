%float2custom Converts double input to IEEE754-like floating point number,
%             with custom bit-width of fraction and exponent parts
%  call methods:
%  [out] = float2custom(in, Ne, Nf)
%  
%  parameters:
%  in - vector of input data
%  Ne - custom float exponent part bit-width
%  Nf - custom float fractio part bit-width
%
%  Ne should be positive greater then 1 and less then 53
%  Nf should be positive non-zero value 
%  Sum on Ne and Nf should be less then 64 (result saved as uint 64).
%  
%%*********************vmodel MATLAB Verilog simulator*********************
%%Moscow, Control Problems Department MIREA, 2009-2014
%%Authors: Romanov A
%%
%%Distributed under the GNU LGPL
%%*************************************************************************

function [out] = float2custom(in, Ne, Nf)
    if(Ne+Nf>64)
        error('float2custom error: Ne+Nf>64');
    end    
    if(Ne<2)
        error('float2custom error: Ne<2');
    end
    if(Ne>52)
        error('float2custom error: Ne>52');
    end
    if(Nf<1)
        error('float2custom error: Nf<1');
    end
    Ne_mask=bitshift(1,Ne)-1;               %mask with Ne ones
    Ne_mask2=bitshift(1,Ne-1);              %mask with 1 folowed with Ne-2 zeros
    in_i=typecast(double(in), 'uint64' );   %converting all inputs to double
    sgns=(in_i>=2^63);                      %sign
    ex=int64(bitand(bitshift(in_i,-52),2047));     %exponent
    frac=bitand(in_i,4503599627370495);     %fraction
    frac=bitshift(frac,Nf-52);              %changing fractiom size to Nf
%     if(ex==2047)
%        ex=Ne_mask;
%     elseif (ex~=0)                        %if ex=0 then we keep it
%         if(abs(ex-1024)>=Ne_mask)
%             ex=Ne_mask;
%             frac=0;
%         else
%             ex=(ex-1024)+Ne_mask2; %changing exponent size to Ne
%         end    
%     end
    ex=((ex-1024)+Ne_mask2).*int64(ex~=0).*int64(ex~=2047)+Ne_mask.*int64(ex==2047);  %the same code as commented above, but in vector form
    out=frac+uint64(double(ex)*2^Nf+sgns*2^(Nf+Ne)); %building final result. Using power due to bitshift bugs with numbers  > 2^52
end