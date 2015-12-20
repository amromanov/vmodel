%%*********************vmodel MATLAB Verilog simulator******************
%%Moscow, Control Problems Department MIREA, 2009-2014
%%Authors: Karyakin D, Romanov A
%%
%%Distributed under the GNU LGPL
%%**********************************************************************

function [] = compile(gl, file_to_compile)
%COMPILE Summary of this function goes here
%   file_to_compile - main cpp file without extension and path
%   must_be_located in save folder with .v file

  obj_dir = [ gl.src_path 'obj_dir'];

  if (size(file_to_compile, 1) == 0)
    %compilation of including files
    
    %search for .cpp files in obj_dir
    ll = dir([obj_dir gl.slash '*.cpp']);
    
    if gl.coverage
        cov_include_path='-DVM_COVERAGE ';
    else
        cov_include_path='';
    end
    
    for k=1:length(ll) 
      %compile all .cpp files in obj_dir
      s = ['mex -outdir ''' obj_dir ''' -c -I"' gl.v_path 'include" ' ...
         cov_include_path ...
         '-I"' gl.v_path 'include' gl.slash 'vltstd" "'...
         obj_dir gl.slash ll(k).name '"'];
      eval(s);
    end
    
    %compile verilated.cpp into obj_dir 
    s = ['mex -outdir ''' obj_dir ''' -c -DVMODEL_SIM -I"' gl.v_path 'include" "' ... 
       gl.v_path 'include' gl.slash 'verilated.cpp"'];
    eval(s);

    %compile SpCoverage.cpp into obj_dir 
    if (gl.coverage)
        s = ['mex -outdir ''' obj_dir ''' -c -DVM_COVERAGE -I"' gl.v_path 'include" "' ... 
           gl.v_path 'include' gl.slash 'verilated_cov.cpp"'];
        eval(s);        
    end
    
    
    
  else
    %compile main cpp and build mex-file
    
    if(gl.DoWindows)
      o_mask = '.obj';
    else
      o_mask = '.o';
    end    
    
    ll = dir([obj_dir gl.slash '*' o_mask]);
        
    %o_files is a string, containing full paths of all needed object files,
    %file_to_compile first
    %#ok<*AGROW>
    o_files = [ '"' obj_dir gl.slash file_to_compile o_mask '" ']; 
    for k=1:length(ll)
      o_files = [o_files ' "' obj_dir gl.slash ll(k).name '"'];
    end 
    
    %compilation of top cpp file into o file
    s = ['mex -outdir ''' obj_dir ''' -c -I"' gl.v_path 'include" ' ...
      '-I"' gl.v_path 'include' gl.slash 'vltstd" "'...          
      gl.src_path file_to_compile '.cpp"'];
    eval(s);
    
    % build all
    s = ['mex -outdir ''' gl.output_dir ''' -output "' ...
      file_to_compile '" ' o_files];
    eval(s);
  end
  
end

