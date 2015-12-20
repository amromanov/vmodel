%%*********************vmodel MATLAB Verilog simulator******************
%%Moscow, Control Problems Department MIREA, 2015
%%Authors: Romanov A
%%
%%Distributed under the GNU LGPL
%%**********************************************************************

function [ random_chg_set ] = generate_rchg_data( gl )
    random_chg_set ='';  
    for i = 1:size(gl.outputs, 2)  %Adding random modification
        if(gl.outputs{i}.type~=2)    %skipping all inputs and outputs, and changing only interal signals
            continue
        end
        sig_size=gl.outputs{i}.high - gl.outputs{i}.low + 1; %Calculating signal size
        
        [mem_depth, clear_name] = get_mem_depth(gl.outputs{i}.name);

        if(mem_depth > 0)              %if signal is memory     
            if(sig_size<64) %if signal size is lower 64 bit and so signal stored in 1 variable
              if(gl.rchg_full_mem)      %if rchg_full_mem, then adding cycle for change of each memory element
                  random_chg_set = sprintf('%s for(int k=0; k<%i; k++)\n', ...
                      random_chg_set, mem_depth);
              else                      %else change random addresss
                  random_chg_set = sprintf(['%s k=chg_addr(' ...
                      num2str(2^ceil(log2(mem_depth))-1) ','  num2str(mem_depth-1) ');\n'],random_chg_set );
              end
              random_chg_set = sprintf(['%s ' gl.outputs{i}.c_path  clear_name '[k]' ...
                  ' = ' gl.outputs{i}.c_path  clear_name '[k]' ' ^ chg_vector(' ...
                  num2str(2^ceil(log2(sig_size))-1) ',' num2str(sig_size-1) '); \n'],random_chg_set );
            else
              if(gl.rchg_full_mem)      %if rchg_full_mem, then adding cycle for change of each memory element
                  random_chg_set = sprintf('%s for(int k=0; k<%i; k++){\n', ...
                      random_chg_set, mem_depth);
              else                      %else change random addresss
                  random_chg_set = sprintf(['%s k=chg_addr(' ...
                      num2str(2^ceil(log2(mem_depth))-1) ','  num2str(mem_depth-1) ');\n'],random_chg_set );
              end
            
              for word_ind=1:1:gl.outputs{i}.size      %Changing bits in every byte
              if(word_ind==gl.outputs{i}.size)              %only array element can have different size
                sig_size = gl.outputs{i}.high - gl.outputs{i}.low + 1 - (gl.outputs{i}.size-1)*32; 
              else
                sig_size = 32;
              end    
              random_chg_set = sprintf(['%s ' gl.outputs{i}.c_path  clear_name '[k]' '[' num2str(word_ind-1) ']' ...
                 ' = ' gl.outputs{i}.c_path  clear_name '[k]' '[' num2str(word_ind-1) ']' ' ^ chg_vector(' ...
                 num2str(2^ceil(log2(sig_size))-1) ',' num2str(sig_size-1) '); \n'],random_chg_set );
              end    
              if(gl.rchg_full_mem)      %if changing only single element, then there is no use in '}', else          
                random_chg_set = sprintf('%s }\n',random_chg_set );
              end
            end
        else                                                 %if normal signal
            if(sig_size<64) %if signal size is lower 64 bit and so signal stored in 1 variable
              random_chg_set = sprintf(['%s ' gl.outputs{i}.c_path  gl.outputs{i}.name ...
                  ' = ' gl.outputs{i}.c_path  gl.outputs{i}.name ' ^ chg_vector(' ...
                  num2str(2^ceil(log2(sig_size))-1) ',' num2str(sig_size-1) '); \n'],random_chg_set );
            else
                for word_ind=1:1:gl.outputs{i}.size      %Changing bits in every byte
                  if(word_ind==gl.outputs{i}.size)              %only array element can have different size
                      sig_size = gl.outputs{i}.high - gl.outputs{i}.low + 1 - (gl.outputs{i}.size-1)*32; 
                  else
                      sig_size = 32;
                  end    
                  random_chg_set = sprintf(['%s ' gl.outputs{i}.c_path  gl.outputs{i}.name '[' num2str(word_ind-1) ']' ...
                      ' = ' gl.outputs{i}.c_path  gl.outputs{i}.name '[' num2str(word_ind-1) ']' ' ^ chg_vector(' ...
                      num2str(2^ceil(log2(sig_size))-1) ',' num2str(sig_size-1) '); \n'],random_chg_set );
                end                
            end
            
        end 
    end
end


