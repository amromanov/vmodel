function [] = install(verilator_path, do_cygwin)
%%install(verilator_path, do_cygwin);
%%   Function install vmodel simulator
%%verilator_path - full path to verilator
%%do_cygwin - set 1 if you want to configure vmodel to work with
%%preinstalled CYGWIN with G++ compiler.
%%-
%%*********************vmodel MATLAB Verilog simulator******************
%%Moscow, Control Problems Department MIREA, 2009-2015
%%Authors: Karyakin D, Romanov A
%%-
%%Distributed under the GNU LGPL
%%**********************************************************************

  if (nargin  < 1)
    verilator_path = getenv('verilator_path');
    if (isempty(verilator_path) == 1)
        error('Verilator path is not defined');
    end
  end
  
  if (nargin < 2)
    do_cygwin=1;
  end
  
  patch_verilated_cpp(verilator_path);
  
  curdir = mfilename('fullpath');
  lastpos = max([strfind(curdir, '/') strfind(curdir, '\')]);
  if ~isempty(lastpos)
    curdir = curdir(1:lastpos-1);
  end

  vmodeldir1 = [matlabroot '/toolbox/vmodel'];
  if exist(vmodeldir1, 'dir')
    rmdir(vmodeldir1, 's');
  end
  
  mkdir(vmodeldir1);
  vmodeldir2 = [vmodeldir1 '/vmodel'];
  mkdir(vmodeldir2);
  
  filelist = {'bin_stairs.m', 'compile.m', 'data_simulink', 'data_vmodel', ...
    'digital.m', 'digital_delete_fcn.m', 'digital_on_zoom.m', ...
    'matlabmodel.m', 'model_template', 'parse.m', 'sim_template', ...
    'simulinkmodel.m', 'slblocks.m', 'time_freq_template', 'vmodel.m', ...
    'vmodel_blocks.mdl', 'insert_with_params.m', 'float2custom.m', ...
    'custom2float.m' 'vcoverage.m' 'parse_clocks.m' 'create_vcov_file_discription.m', ...
    'check_vcov_level.m', 'parse_vcov_file.m', 'parse_vcov_line.m', ...
    'sort_vcov_by_files.m', 'rmrows.m', 'uint2sign.m', 'get_mem_depth.m',...
    'generate_multiclock_data.m','generate_rchg_data.m'};
  
  for i = 1:length(filelist)
    fname = filelist{i};
    copyfile([curdir '/' fname], [vmodeldir2 '/' fname]);
  end
  
  
  f = fopen([vmodeldir2 '/startup.m'], 'w');
  s = ['setenv(''verilator_path'', ''' verilator_path ''');'];
  eval(s);
  fwrite(f, s);
  if(ispc&&do_cygwin)          %if windows pc, setting CYGWIN flags
      s = ['setenv(''CYGWIN'', ''nodosfilewarning'');'];
      eval(s);
      if(strcmp(computer('arch'),'win64'))
        copyfile([curdir '\mexopts.bat'], prefdir);       %Copying MEX-parameters to MATLAB preferences for x86_64 arch
        sfpref('UseLCC64',1);                             %Setting LCC64 as Stateflow compiler
      end
  end
  fclose(f);
  path(path, vmodeldir2);
  savepath();
  
  fprintf 'Done.\n';
  
end
  
function patch_verilated_cpp(verilator_path)
    fname = [verilator_path 'include/verilated.cpp'];
    f = fopen(fname, 'r');
    if (f < 0)
        error('Can''t open verilated.cpp');
    end
    s = fscanf(f, '%c', inf);
    fclose(f); 
    %check for patched
    tmp = s(1:9);
    if (strcmp(tmp, '//patched') == 0)
        nl = [char(13) char(10)];
        code = ['//patched by vmodel' nl ...
            '//this code allows to output verilator''s errors into MATLAB' nl ...
            '//don''t remove it' nl ...
            '#ifdef VMODEL_SIM' nl ...
            '#include "mex.h"' nl ...
            '#define VL_USER_FATAL' nl ...
            'void vl_fatal(const char* filename, int linenum, ' ...
            'const char* hier, const char* msg) {' nl ...
            'mexErrMsgTxt(msg);' nl ...
            '}' nl,....
            '#endif' nl ...
            ];
        s = [code s];
        f = fopen(fname, 'w');
        fwrite(f, s);
        fclose(f);  
    end
end
