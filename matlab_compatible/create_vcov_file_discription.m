%%*********************vmodel MATLAB Verilog simulator******************
%%Moscow, Control Problems Department MIREA, 2009-2015
%%Authors: Romanov A
%%
%%Distributed under the GNU LGPL
%%**********************************************************************

function create_vcov_file_discription( fdata, out_path )
%CREATE_VCOV_FILE DISCRIPTION gets data from check_vcov_level for one file
%and creates annotated verilog with coverage result in out_path folder
%(For internal use only)
%INPUTS
%fdata    - data from check_vcov_level()
%out_path - path of the folder, where resulting file should be placed

   cur_line=1;
   f=fopen( fdata.filepath,'r');
   fw=fopen([out_path fdata.filename '.v'],'w+');
   digs=ceil(log10(fdata.max_count));   %Calculate maximal number of digits required for coverage count in this file
   while ~feof(f)    
        s=fgets(f);
        line_in_cov=0;
        for i=1:length(fdata.lines)     %Check if this line has coverage information
            if(fdata.lines(i).line_number==cur_line)
                if(fdata.lines(i).low_level)
                    fprintf(fw,'%%');           %marking lines, that has not passed coverage test with %
                else
                    fprintf(fw,' ');
                end
                fprintf(fw,['%' int2str(digs) 'i\t%s'],fdata.lines(i).count,s);  %adding coverage count information in front of line
                line_in_cov=1;
                break;
            end
        end
        if (~line_in_cov)
            fprintf(fw,' \t%s',s);          %if line doesn't have coverage information, then just reprinting it
        end
        cur_line=cur_line+1;
   end
   fclose(f);
   fclose(fw);
end

