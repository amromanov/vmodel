function [mem_depth, clear_name] = get_mem_depth(name)
  % return size of memory for outputs like 'data_out[12]'
  % mem_depth will be 12, clear name 'data_out'
  % for output like 'data' mem_depth will be 0, clear name 'data'
  a = strfind(name, '[');
  if (isempty(a))
    mem_depth = 0;
    clear_name = name;
  else
    mem_depth = str2double(name(a(1) + 1:end-1));
    clear_name = name(1:a(1) - 1);
  end  
end