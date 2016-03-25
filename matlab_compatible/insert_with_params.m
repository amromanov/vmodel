function insert_with_params( input_fname, output_fname, module_params, top_module)
% function insert_with_params( input_fname, output_fname, module_params, top_module)
% INSERT_WITH_PARAMS Function creates parameterized TOP module
% Required params
%   INPUT_FNAME - name of input file (with extention)
%   OUTPUT_FNAME - name of output file (with extention)
%   MODULE_PARAMS - struct with module's parameters
% Additional parameter
%   TOP_MODULE - the name of the top module in the file INPUT_FNAME
%  
%   each field of module_params is considered as a pair parameter-value, 
%   where name of the field is name of parameter, and value of the field
%   is value of parameter. All parameters, that are presend in
%   module_params and lacks in module, will be ignored. Parameter value
%   must be a number or string.
%   --- call example ---
%   params.N = 10;
%   params.S = 'N + 2';
%   insert_with_params('module_name.v', 'new_module_name.v', params);
%   if function has only one argument or output_fname is empty, then 
%   it returns module insertion template


%% check for input number

if(nargin<4)
    top_module = [];
end
    
if(nargin<3)
    module_params=[];
end

if(nargin<2)
    output_fname='';
end

if(~exist(input_fname,'file'))
    disp('Input file doesn''t exist!');
    return
end

%% read input file
	handle = fopen(input_fname);
	s = fscanf(handle, '%c', inf);
	fclose(handle);
    
%% delete all comments, defines, extract pure source
    % state machine: 0 - normal, 1 - after slash, 2 - after /*, 
    % 3 - after //, 4 - after /**, 5 - after `
    
    state = 0;
    source = blanks(length(s)); % destination string
    source_index = 1;  % last written character

    % state machine
    for i = 1:length(s)
        switch state
            case 0
                if (s(i) == '/') %maybe starts comment
                    state = 1;
                elseif ( (s(i) == char(13)) || (s(i) == char(10)) ) %new line
                    source(source_index) = ' ';
                    source_index = source_index + 1;
                else %plain text
                    if(s(i)==9)
                        source(source_index) = ' ';     %Changing tabs into spaces
                    else
                        source(source_index) = s(i);
                    end
                    source_index = source_index + 1;
                end
            case 1
                if (s(i) == '*') % multiline (/*) comment starts
                    state = 2;
                elseif (s(i) == '/') % single-line (//) comment starts
                    state = 3;
                elseif ( (s(i) == char(13)) || (s(i) == char(10)) ) % new line, no comment starts
                    source(source_index) = '/';
                    source(source_index) = ' ';
                    source_index = source_index + 2;
                else % plain text, no comment starts
                    source(source_index) = '/';
                    source(source_index+1) = s(i);
                    source_index = source_index + 2;
                end                    
            case 2
                if (s(i) == '*') % star in multiline comment (/* *)
                    state = 4;
                end
            case 3
                if ( (s(i) == char(13)) || (s(i) == char(10)) ) % new_line, end of single-line comment
                    state = 0;
                    source(source_index) = ' ';
                    source_index = source_index + 1;
                end
            case 4
                if (s(i) == '/')    % end of multiline comment
                    state = 0;  
                % star in multiline comment - do nothing
                elseif (s(i) ~= '*') % plain text in multiline comment 
                    state = 2;
                end
            case 5
                if ( (s(i) == char(13)) || (s(i) == char(10)) ) % new_line, end of define
                    state = 0;
                    source(source_index) = ' ';
                    source_index = source_index + 1;
                end                
        end
    end
    
    
    %% Keep only the module we need as top_module
    expr = 'module\W.*?endmodule(\s|^)';
    s = regexp(source, expr, 'match');
    
    if ~isempty(top_module)
        expr = 'module\s*(?<n>\w*?)[\s#;(]';
        for i=1:length(s)
            e = regexp(s{i}, expr, 'names');
            if length(e)>0
                if strcmp(e(1).n, top_module)==1
                    source = s{i};
                end
            end
        end
    else
        source = s{1}; % If top_module is not specified the first one is used
    end
    
    %% extract the module name
    expr = 'module\s*(?<n>\w*)';
    name = regexp(source, expr, 'names');
    
    if length(name) < 1
        error('Keyword ''module'' expected');
    end
    old_module_name = name(1).n;

    
    %% Extract header and body of the module
    header = regexp(source, 'module.*?;', 'match');
    hend   = regexp(source, 'module.*?;', 'end');
    if length(header)>0
        header = header{1};
        body = source(hend(1)+1:end);
    else
        header = '';
        body = source;
    end
    
    %% grep all parameters
    
    % % Collect Verilog2001-style parameters
    plist = {};
    expr = '#(?<p>\(.*?);';
    header_params = regexp(header, expr, 'names');
    param_end = 1;
    if length(header_params) > 0
        header_params = header_params(1).p;
        ind = regexp(header_params, '[()]', 'start');
        cnt = 0;
        for i=1:length(ind)
            if header_params(ind(i)) == '('
                cnt = cnt + 1;
            else 
                cnt = cnt - 1;
            end
            if (cnt == 0)
                header_params = header_params(1:ind(i));
                param_end = ind(i);
                break;
            end
        end
    end
    header_params = [header_params(2:end-1) ';']; % semicolon is added for regexp unification
    header_inouts = [header(param_end:end) ';'];
    
    % The rest of module with Verilog95-style parameters
    source_params = [header_params body];
    source_inouts = [header_inouts body];
    
    % Split the source to "parameter A,B,... ;" strings
    expr = 'parameter(?<b>.*?);';
    rec = regexp(source_params, expr, 'names');
    
    % Parse each string separately
    cnt = 1;
    expr = '\s*(?<n>\w*?)\s*=\s*(?<v>.*)\s*';
    for i=1:length(rec)
        item = regexp(rec(i).b, ',', 'split');
        for j=1:length(item)
            param = regexp(item(j), expr, 'names');
            if length(param)>0
                plist{cnt}.name = param{1}.n;
                plist{cnt}.value = param{1}.v;
            end
            fprintf('%3d:  name=%s  value=%s\n', cnt, plist{cnt}.name, plist{cnt}.value);
            cnt = cnt + 1;
        end
    end
    
    %% grep all inouts
    ilist = {};
    
    % Split the source to "(input|inout|output) A,B,...;" strings
    expr = '(?<t>input|inout|output)\s(?<c>[^;]*)';
    rec = regexp(source_inouts, expr, 'names');

    % Parse each string separately
    cnt = 1;
    expr = '\s*(reg|wire)?\s*(?<b>\[[\s\w-:]*\])?\s*(?<n>.*)';
    for i=1:length(rec)
        if strcmp(rec(i).t, 'input')
            inout_type = 1;
        elseif strcmp(rec(i).t, 'output')
            inout_type = 2;
        elseif strcmp(rec(i).t, 'inout')
            inout_type = 3;
        else
            % This should never happen
            fprintf('err_%s_%s_%s_\n', inouts(i).t, inouts(i).b, inouts(i).n)
        end

        item = regexp(rec(i).c, ',', 'split');
        for j=1:length(item)
            param = regexp(item(j), expr, 'names');
            if length(param)>0
                ilist{cnt}.name       = param{1}.n;
                ilist{cnt}.inout_type = inout_type;
                ilist{cnt}.brackets   = param{1}.b;
            end
            fprintf('%3d:  name=%s  value=%s\n', cnt, plist{cnt}.name, plist{cnt}.value);
            cnt = cnt + 1;
        end
        
    end
    
    %% modify values of parameters according with in parameters
    for i = 1:length(plist)
        param_name = plist{i}.name;
        if (isfield(module_params, param_name))
            field_value = module_params.(param_name);
            if (isreal(field_value))
                field_value = num2str(field_value);
            end
            plist{i}.value = field_value;            
        end
    end
    
%% compose output file
    output_str = [];
    nl = [char(13) char(10)];
    % extract module name
    if(~isempty(output_fname))
        dot_pos = 0;
        slash_pos = 0;
        for i = length(output_fname):-1:1
            if (dot_pos == 0)
                if (output_fname(i) == '.')
                    dot_pos = i;
                end
            else
                if (~isletter(output_fname(i)) && output_fname(i) ~= '_')
                    slash_pos = i;
                    break;
                end
            end
        end
        if (dot_pos == 0)
            error('Can''t find ''.'' in output filename');
        else
            module_name = output_fname(slash_pos+1:dot_pos-1);
        end

        % write parameters

        output_str = ['module ' module_name ' '];
        if (isempty(plist))
            output_str = [output_str nl];
        else
            output_str = [output_str '#(parameter '];
            for i = 1:length(plist)
                if (i > 1)
                    output_str = [output_str ', '];
                end
                output_str = [output_str plist{i}.name '=' plist{i}.value];
            end
            output_str = [output_str ')' nl];
        end

        % write inputs
        output_str = [output_str '(' nl];
        for i = 1:length(ilist)
            if (ilist{i}.inout_type == 1)
                tpe = 'input ';
            elseif (ilist{i}.inout_type == 2)
                tpe = 'output ';
            else
                tpe = 'inout ';
            end
            output_str = [output_str char(9) tpe ilist{i}.brackets ilist{i}.name];
            if (i < length(ilist))
                output_str = [output_str ','];
            end
            output_str = [output_str nl];
        end
        output_str = [output_str ');' nl nl];
    else
        nl = [char(10)];
    end
    
    % insert module
    output_str = [output_str old_module_name];
    if (~isempty(plist))
        output_str = [output_str ' #('];
        for i = 1:length(plist)
            if (i > 1)
                output_str = [output_str ','];
            end
            pname = plist{i}.name;
            output_str = [output_str '.' pname '(' pname ')'];
        end
        output_str = [output_str ')'];
    end
    output_str = [output_str nl old_module_name '(' nl];
    for i = 1:length(ilist)
        iname = ilist{i}.name;
        output_str = [output_str char(9) '.' iname '(' iname ')'];
        if (i < length(ilist))
            output_str = [output_str ','];
        end
        output_str = [output_str nl];
    end
    output_str = [output_str ');' nl];
    if(~isempty(output_fname))
        output_str = [output_str  'endmodule'];
    end

%% store file
    if(isempty(output_fname))
        fprintf('%c',[output_str]);
    else
        handle = fopen(output_fname, 'w');
        fprintf(handle, '%c', output_str);
        fclose(handle);
        disp('done.');
    end
end

