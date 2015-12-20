%%*********************vmodel MATLAB Verilog simulator******************
%%Moscow, Control Problems Department MIREA, 2009-2015
%%Authors: Romanov A
%%
%%Distributed under the GNU LGPL
%%**********************************************************************

function [results]=parse_vcov_file(filename)
%PARSE_V_VCOV_FILE parses coverage files, produced by vmodel and prepares
%data for other vmodel coverage analysis functions (For internal use only)
%INPUTS
%filename - path to coverage information file. By default - coverage.dat
%OUTPUTS
%results  - structured raw data with coverage results, parsed from
%coverage.dat

if(nargin<1)
    filename='coverage.dat';
end    

results=[];
if exist(filename,'file')   
    %File scan
    f=fopen(filename,'r');
    data=fgets(f);
    if ~isempty((strfind(data,'# SystemC::Coverage-3'))) %Cheking for header in first line
        while (~feof(f))   %Scaning file
            data=fgets(f);
            res=parse_vcov_line(data);
            if ~isempty(res)
                results=[results; res];
            end
        end
    end
    fclose(f);

    %Converting strings to numbers
    for i=1:length(results)
        results(i).l=str2num(results(i).l);
        results(i).n=str2num(results(i).n);
        results(i).count=str2num(results(i).count);
    end
end

end