%vcoverage reads the specified data file and generates annotated source
%  code with coverage metrics annotated. By default logs/coverage.pl is
%  read.
%
%  call methods:
%  [prcnt,covered_lines,total_lines] = vcoverage( level, strict_cov, ignore_list, filename, output_path )
%  [prcnt,covered_lines,total_lines] = vcoverage( level, strict_cov, ignore_list, filename )
%  [prcnt,covered_lines,total_lines] = vcoverage( level, strict_cov, ignore_list )
%  [prcnt,covered_lines,total_lines] = vcoverage( level, strict_cov )
%  [prcnt,covered_lines,total_lines] = vcoverage( level )
%  [prcnt,covered_lines,total_lines] = vcoverage
%  
%  parameters:
%  level       - Specifies the minimum occurrence count that should be flagged if the
%                coverage line does not include a specified threshold.
%                Defaults to 100.
%  strict_cov  - Switchs on/off strict coverage mode. If line have more then
%                on coverage point, then in strict mode occurrence count for
%                this line will be mininmum from all coverage points, and in
%                normal mode, count will be sum of counts from all coverage
%                points. Defaults to 0 (normal mode).
%  ignore_list - cell vector of module names (filenames without .v
%                extenstions), which should be ignored during coverage
%                analysis. For example {'top', 'adder'}. Default: {};
%  filename    - Path to files with raw coverage information. Could be
%                string or cell array of strings. 
%                Defaults to 'coverage.dat'
%  output_path - path of the folder, where resulting files should be placed.
%                Defaults to ./coverage_source/
%
%  results:
%  prcnt         - Coverage level in percents
%  covered_lines - Number of lines covered by tests
%  total_lines   - Total number of lines, involved in coverage analysis
%  
%%*********************vmodel MATLAB Verilog simulator*********************
%%Moscow, Control Problems Department MIREA, 2009-2015
%%Authors: Romanov A
%%
%%Distributed under the GNU LGPL
%%*************************************************************************

function [  prcnt, covered_lines, total_lines ] = vcoverage( level, strict_cov, ignore_list, filename, output_path )

    %if no output path
    if(nargin<5)
       if(isunix)
         output_path='./coverage_source/';
       else
         output_path='coverage_source\';
       end
    end
    
    if(~isempty(output_path))
        if ((output_path(end)~='\')&&(output_path(end)~='/'))
            if(isunix)
                output_path=[output_path '/'];
            else
                output_path=[output_path '\'];
            end
        end
    end

    %if no filename info
    vdata=[];
    if(nargin<4)
        vdata=parse_vcov_file;
    else
        if(iscell(filename))
            for i=1:length(filename)
                vdata=[vdata; parse_vcov_file(cell2mat(filename(i)))];            
            end
        else
            vdata=parse_vcov_file(filename);
        end
    end

    %if no ignore list
    if(nargin<3)
        ignore_list={};
    end

    %if no strict level set, then by default Strict coverage mode is disabled
    if(nargin<2)
        strict_cov=0;
    end

    %if level is not set, then
    if(nargin<1)
        level = 100;
    end

    [cov_data,total_lines, covered_lines]=check_vcov_level(vdata,level,strict_cov,ignore_list);
    
    if(total_lines>0)
        prcnt = [covered_lines/total_lines*100];  %Coverage in percents
    else
        prcnt = 0;
    end
    
    mkdir(output_path);  %Making directory for coverage results files

    
    for i=1:length(cov_data)
        if ((~cov_data(i).ignore)&&(cov_data(i).low_level))  %if file is not from ignore list, has incovered lines
            create_vcov_file_discription(cov_data(i),output_path);
        end    
    end

    
end