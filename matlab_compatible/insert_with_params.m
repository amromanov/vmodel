function [] = insert_with_params( input_fname, output_fname, module_params )
%INSERT_WITH_PARAMS Function creates TOP module with required params
%   INPUT_FNAME - name of input file (with extention)
%   OUTPUT_FNAME - name of output file (with extention)
%   MODULE_PARAMS - struct with module's parameters
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
    
%% delete all comments, defines, extract pure header till semicolon
    % state machine: 0 - normal, 1 - after slash, 2 - after /*, 
    % 3 - after //, 4 - after /**, 5 - after `
    
    state = 0;
    header = blanks(length(s)); % destination string
    header_index = 1;  % last written character

    % state machine
    for i = 1:length(s)
        switch state
            case 0
                if (s(i) == '/') %maybe starts comment
                    state = 1;
                elseif (s(i) == '`') %start of define
                    state = 5;
                elseif (s(i) == ';') % end of header
                    break;
                elseif ( (s(i) == char(13)) || (s(i) == char(10)) ) %new line
                    header(header_index) = ' ';
                    header_index = header_index + 1;
                else %plain text
                    if(s(i)==9)
                        header(header_index) = ' ';     %Changing tabs into spaces
                    else
                        header(header_index) = s(i);
                    end
                    header_index = header_index + 1;
                end
            case 1
                if (s(i) == '*') % multiline (/*) comment starts
                    state = 2;
                elseif (s(i) == '/') % single-line (//) comment starts
                    state = 3;
                elseif ( (s(i) == char(13)) || (s(i) == char(10)) ) % new line, no comment starts
                    header(header_index) = '/';
                    header(header_index) = ' ';
                    header_index = header_index + 2;
                else % plain text, no comment starts
                    header(header_index) = '/';
                    header(header_index+1) = s(i);
                    header_index = header_index + 2;
                end                    
            case 2
                if (s(i) == '*') % star in multiline comment (/* *)
                    state = 4;
                end
            case 3
                if ( (s(i) == char(13)) || (s(i) == char(10)) ) % new_line, end of single-line comment
                    state = 0;
                    header(header_index) = ' ';
                    header_index = header_index + 1;
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
                    header(header_index) = ' ';
                    header_index = header_index + 1;
                end                
        end
    end
    
    header = header(1:header_index - 1);
%% split header into sections
    % first we search first appearance of ( or #
    app = 0;
    for index = 1:header_index - 1
        if ((header(index) == '(') || (header(index) == '#'))
            app = index;
            break;
        end
    end
    
    % if no one found - then header is invalid
    if (app == 0)
        error('Invalid header: expected ''('' or ''#''');
    end
    
    % extract module name
    head = strtrim(header(1:app-1));
    if (length(head) < 7)
        error('Keyword ''module'' expected');
    else
        if (~strcmp(head(1:7), 'module '))
            error('Keyword ''module'' expected');
        end
    end
    old_module_name = strtrim(head(8:end));    
    
    
    parameters = '';
    if (header(app) == '#')
        % parse string with parameters
        bracket_level = 0;
        first_bracket = 0;
        last_bracket = 0;
        for index = app+1:header_index-1
            if (header(index) == '(')   % ( after # or in equation
                if (bracket_level == 0)
                    first_bracket = index;
                end
                bracket_level = bracket_level + 1;
            % after # and ( can be only spaces
            elseif ((first_bracket == 0) && (header(index) ~= ' ')) 
                error('Unexpected symbol after ''#''');
            elseif (header(index) == ')')
                bracket_level = bracket_level - 1;
                if (bracket_level == 0)
                    last_bracket = index;
                    break;
                end
            end
        end
        parameters = header(first_bracket+1:last_bracket-1);
        app = last_bracket;
    else
        app = app - 1;
    end

    
    % parse second pair of parentheses, with description of inputs/outputs
    bracket_level = 0;
    first_bracket = 0;
    last_bracket = 0;
    for index = app+1:header_index-1
        if (header(index) == '(')   % ( after parameters or in equation
            if (bracket_level == 0)
                first_bracket = index;
            end
            bracket_level = bracket_level + 1;
        % after parameters can be only spaces
        elseif ((first_bracket == 0) && (header(index) ~= ' ')) 
            error('Unexpected symbol after between description of parameters and inputs/outputs');
        elseif (header(index) == ')')
            bracket_level = bracket_level - 1;
            if (bracket_level == 0)
                last_bracket = index;
                break;
            end
        end
    end
    inouts = header(first_bracket+1:last_bracket-1);
    
%% parse list of parameters
    if isempty(parameters)
        param_list = {};
    else
        param_list = regexp(parameters, ',', 'split');
    end
    
    plist = cell(1, length(param_list));
    
    for index = 1:length(param_list)
        item = param_list{index};
        item_parts = regexp(item, '=', 'split');
        if (length(item_parts) ~= 2)
            error('Invalid description of parameters');
        end
        param_name = strtrim(item_parts{1});
        % remove word 'parameter' if one exists
        if (length(param_name) > 9)
            if (strcmp(param_name(1:10), 'parameter '))
                param_name = strtrim(param_name(11:end));
            end
        end
        param_value = strtrim(item_parts{2});
        plist{index}.name = param_name;
        plist{index}.value = param_value;
    end
    
%% parse list of inouts
    inouts_list = regexp(inouts, ',', 'split');
    ilist = cell(1, length(inouts_list));
    for index = 1:length(inouts_list)
        % read type of inout (input, output, inout)
        item = [strtrim(inouts_list{index}) blanks(10)];
        if (strcmp(item(1:6), 'input '))
            inout_type = 1;
        elseif (strcmp(item(1:7), 'output '))
            inout_type = 2;
        elseif (strcmp(item(1:6), 'inout '))
            inout_type = 3;
        else
            error('expected ''input'', ''output'' or ''inout'' in description of inouts');
        end
        item = [strtrim(item(7:end)) blanks(10)];
        
        % remove words 'reg' and 'wire', if any
        if (strcmp(item(1:4), 'reg ') || strcmp(item(1:5), 'wire '))
            item = [strtrim(item(5:end)) blanks(10)];
        end
        
        % find brackets
        if (item(1) == '[')
            b = strfind(item, ']');
            if (length(b) ~= 1)
                error('Distinct number of left and right brackets in inout''s description');
            end
            brackets = item(1:b(1));
            item = item(b(1)+1:end);
        else
            brackets = '';
        end
        item = strtrim(item);
        
        ilist{index}.name = item;
        ilist{index}.inout_type = inout_type;
        ilist{index}.brackets = brackets;
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

