%%*********************vmodel MATLAB Verilog simulator******************
%%Moscow, Control Problems Department MIREA, 2009-2015
%%Authors: Romanov A
%%
%%Distributed under the GNU LGPL
%%**********************************************************************

function [result] = sort_vcov_by_files(in_data)
%SORT_VCOV_BY_FILES sorts data from parse_vcov_file() grouping it by
%files and lines(For internal use only)
%INPUTS
%in_data -  data from parse_vcov_file()
%OUTPUTS
%result  - structure with coverage data, grouped by files and lines

    vdata=in_data;
    fdata=[];

    %Sort by files
    fn_num=0;  %Number of file name
    while ~isempty(vdata)
       fn_num=fn_num+1;
       current_filename=vdata(1).f;     %Getting filename
       fdata(fn_num).filepath=current_filename;
       [pathstr, name, ext] = fileparts(current_filename);
       fdata(fn_num).filename=name;
       i=1;
       line_num=1;
       while (i<=length(vdata))
            if(strcmp(current_filename,vdata(i).f))   %if found filename, copy line to fdata structure and delete from vdata
                fdata(fn_num).lines(line_num)=vdata(i);
                line_num=line_num+1;
                vdata=rmrows(vdata,i);
            else
                i=i+1;
            end
       end
    end

    %Sort by line
    result=[];
    for fn_num=1:length(fdata)
        result(fn_num).filepath=fdata(fn_num).filepath;
        result(fn_num).filename=fdata(fn_num).filename;
        fdata(fn_num).lines=fdata(fn_num).lines';  %transpose lines to make it possible to use removerows func, to remove elements
        cur_line=0;
        while ~isempty(fdata(fn_num).lines)
            cur_line=cur_line+1;
            current_line=fdata(fn_num).lines(1).l;
            result(fn_num).lines(cur_line).line_number=current_line;
            i=1;
            line_num = 1;
            while (i<=length(fdata(fn_num).lines))  %if line have same number as current_line
                if(fdata(fn_num).lines(i).l==current_line) %copy to result and delete from fdata
                    result(fn_num).lines(cur_line).vcov_lines(line_num)=fdata(fn_num).lines(i);
                    fdata(fn_num).lines=rmrows(fdata(fn_num).lines,i);
                    line_num=line_num+1;
                else
                    i=i+1;
                end
            end
        end
    end

end

