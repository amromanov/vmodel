%%*********************vmodel MATLAB Verilog simulator******************
%%Moscow, Control Problems Department MIREA, 2009-2015
%%Authors: Romanov A
%%
%%Distributed under the GNU LGPL
%%**********************************************************************

function [ result, lines_count, lines_covered ] = check_vcov_level( cov_info, level, strict_cov, ignore_list )
%CHECK_VCOV_LEVEL gets data from parse_vcov_file() and prepares data for
%vcoverage function. (For internal use only)
%INPUTS
%cov_info    - data from parse_vcov_file()
%level       - Specifies the minimum occurrence count that should be flagged if the
%              coverage line does not include a specified threshold.
%              Defaults to 100
%strict_cov  - Switchs on/off strict coverage mode. If line have more then
%              on coverage point, then in strict mode occurrence count for
%              this line will be mininmum from all coverage points, and in
%              normal mode, count will be sum of counts from all coverage points
%ignore_list - cell vector of module names (filenames without .v
%              extenstions), which should be ignored during coverage
%              analysis
%OUTPUT
%result        - output stucture with coverage analysis results
%lines_count   - total line count in current coverage analysis
%lines_covered - number of lines, that passed test (level>=count)


data=sort_vcov_by_files(cov_info);  %Sort coverage info by files and lines

lines_count = 0;
lines_covered = 0;

for i=1:length(data)
    data(i).max_count=0;
    data(i).ignore=0;
    data(i).low_level=0;   %Setting low level flag to zero
    data(i).lines_covered=0;
    data(i).lines_count=length(data(i).lines);
    %Checking file in ignore list
    for ic=1:length(ignore_list)
        if(strcmp(cell2mat(ignore_list(ic)),data(i).filename))
            data(i).ignore=1;
            break
        end
    end
    
    if(data(i).ignore)      %if file is in ignore list, then switching to next file
        continue
    end
        
    for j=1:length(data(i).lines)
        data(i).lines(j).low_level=0;   %Setting low level flag to zero
        data(i).lines(j).max_count=data(i).lines(j).vcov_lines(1).count;
        if(strict_cov)
            data(i).lines(j).count=data(i).lines(j).vcov_lines(1).count;
        else
            data(i).lines(j).count=0;
        end
        for k=1:length(data(i).lines(j).vcov_lines)
            if(data(i).lines(j).vcov_lines(k).count>data(i).lines(j).max_count)  %Saving the smallest count value for line 
                data(i).lines(j).max_count=data(i).lines(j).vcov_lines(k).count;                
            end
            %if Strict coverage mode is on, then count for the line
            %minimal count from all coverage data for this line
            %if Strict coverage mode is off, then count for the line
            %is sum of counts from all coverage data for this line
            if(strict_cov)  
                if(data(i).lines(j).vcov_lines(k).count<data(i).lines(j).count)  %Saving the smallest count value for line 
                   data(i).lines(j).count=data(i).lines(j).vcov_lines(k).count;                
                end
            else
                   data(i).lines(j).count= data(i).lines(j).count+data(i).lines(j).vcov_lines(k).count;                                
            end
        end
        if(data(i).lines(j).count<level)
            data(i).low_level=1;   %Setting low level flag for file
            data(i).lines(j).low_level=1;   %Setting low level flag for line
        else
            data(i).lines_covered=data(i).lines_covered+1; %Incrementin covered lines counter
        end
        if (data(i).max_count<data(i).lines(j).count)
            data(i).max_count=data(i).lines(j).count;
        end
    end
    lines_count   = lines_count   + data(i).lines_count;
    lines_covered = lines_covered + data(i).lines_covered;  
end

result=data;

end

