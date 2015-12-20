%custom2float Converts IEEE754-like floating point number, with custom 
%             bit-width of fraction and exponent parts to double
%  call methods:
%  [out] = custom2float(in, Ne, Nf)
%  
%  parameters:
%  in - vector of input data in uint64 format
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

function [ out ] = custom2float(in, Ne, Nf)
    if(Ne+Nf>64)
        error('custom2float error: Ne+Nf>64');
    end    
    if(Ne<2)
        error('custom2float error: Ne<2');
    end
    if(Ne>52)
        error('custom2float error: Ne>52');
    end
    if(Nf<1)
        error('custom2float error: Nf<1');
    end
    Ne_mask2=bitshift(1,Ne-1);       %mask with 1 folowed with Ne-2 zeros
    Ne_mask=bitshift(1,Ne)-1;        %mask with Ne ones
    
    in_i=uint64(in);   %converting all inputs to double
    sgns=(in_i>=2^(Ne+Nf));                             %sign
    ex=int64(bitand(bitshift(in_i,-Nf),Ne_mask));       %exponent
    frac=in_i-uint64(double(ex*2^Nf)+sgns*2^(Ne+Nf));   %fraction Using power due to bitshift bugs with numbers > 2^52
    frac=bitshift(frac,52-Nf);                          %changing fractiom size to 52
%     if(ex==Ne_mask)
%         ex=2047;
%     elseif (ex~=0)                          %if ex=0 then we keep it
%         if(abs(ex-Ne_mask2)>=1024)
%             ex=2047;
%             frac=0;
%         else
%             ex=(ex-Ne_mask2)+1024; %changing exponent size to Ne
%         end    
%     end
    ex=((ex-Ne_mask2)+1024).*int64(ex~=0).*int64(ex~=Ne_mask)+2047.*int64(ex==Ne_mask); %the same code as commented above, but in vector form
    out_i=frac+uint64(double(ex*2^52)+sgns*2^63);  %building final result. Using power due to bitshift bugs with numbers  > 2^52
    out=typecast(out_i,'double');    
end

