%DIGITAL Outputs digital signals
%  call methods:
%  digital(time, data)
%  digital(time, data, signal_name)
%  digital(time, data, signal_name, type)
%  digital(time1, data1, (signal_name1), (type1), time_2, data2, (signal_name2), (type2)  ...)
%
%  parameters:
%  data - matrix of input data
%  time - matrix of times, must have same dimentions as data
%  signal_name - name of signal to display. Optional.
%  type - representation of numbers. 'b' = binary, 'o' = octal, 'd' = decimal, 'h' = hexadecimal
%  's' is for displaying signed signals. 
%  it's allowed to specify number of bits of integer part and of fractional
%  part. It's allowed to specify only number of bits of integer part.
%  eg: 'sb10.3' - display number in binary format, signed, 10 bits in
%  integer part, 3 bits in fractional part
%  For floating numbers use type
%  'f' or 'fd' = double, 'fs' = single, 'fc' - custom float.
%  For custom float you have to specify size of fraction and exponent in
%  format fcE.F, where E - size of exponent and M - size of fraction.
%  eg: 'fc8.23 - display number as floating point with 8 bit exponent and
%  23 bit of fraction part
%%*********************vmodel MATLAB Verilog simulator******************
%%Moscow, Control Problems Department MIREA, 2009-2015
%%Authors: Karyakin D, Romanov A
%%- 
%%Distributed under the GNU LGPL
%%**********************************************************************

function [] = digital(varargin)
    global gl;
    first_time = 1;
    signal_count = 0;
    index = 1;
    args = {};
    if (~ischar(varargin{1}))
        times = minmax(cell2mat(varargin(1)));
    else
        times = minmax(cell2mat(varargin(2)));
    end

    for i = 1:nargin
        sz = size(varargin{i});
        if (sz(1) > 1)
            if (sz(2) > 1)
                error(['parameter ' int2str(i) ' has both dimensions more than 1']);
            else
                varargin{i} = varargin{i}';
            end
        end
    end
    while (index <= nargin)
        % first parameter might be '+' char, it means that digital 
        % was called from 'digital_on_zoom.m'
        if (ischar(varargin{index}))
            first_time = 0;
            index = index + 1;
        end
        params_rest = nargin + 1 - index;
        if (params_rest == 1)
            times = varargin{index};
            index = index + 1;
        elseif (params_rest == 2)
            signal_count = signal_count + 1;
            timetable = varargin{index};
            matrix = varargin{index + 1};
            sig_name = ['signal' int2str(signal_count)];
            base = 'd';
            args = [args timetable matrix sig_name base];
            times(1) = min(times(1), timetable(1));
            times(2) = max(times(2), timetable(size(timetable, 2)));
            index = index + 2;
        elseif (params_rest == 3)
            signal_count = signal_count + 1;
            timetable = varargin{index};
            matrix = varargin{index + 1};
            if ischar(varargin{index + 2})
                sig_name = varargin{index + 2};
                index = index + 3;
            else
                sig_name = ['signal' int2str(signal_count)];
                index = index + 2;
            end
            base = 'd';
            args = [args timetable matrix sig_name base];
            times(1) = min(times(1), timetable(1));
            times(2) = max(times(2), timetable(size(timetable, 2)));
        else
            signal_count = signal_count + 1;
            timetable = varargin{index};
            matrix = varargin{index + 1};
            if ischar(varargin{index + 2})
                sig_name = varargin{index + 2};
                if (ischar(varargin{index + 3}))
                    base = varargin{index + 3};
                    index = index + 4;
                else
                    base = 'd';
                    index = index + 3;
                end
            else
                sig_name = ['signal' int2str(signal_count)];
                base = 'd';
                index = index + 2;
            end
            args = [args timetable matrix sig_name base];
            times(1) = min(times(1), timetable(1));
            times(2) = max(times(2), timetable(size(timetable, 2)));
        end
    end
        
    %% Initializing axes

    if (signal_count == 0)
        error('No input data')
    end
    
    ax = gca();
    cla();
    %store in axes tag information about matrix and other parameters
    set(ax, 'XLim', [times(1), times(2)]);
    if (first_time == 1)
            z = zoom;
            p = pan;
        setAxesZoomMotion(z,gca,'horizontal');
        %sets callbacks
        set(z,'ActionPostCallback',@digital_on_zoom);
        set(p,'ActionPostCallback',@digital_on_zoom);
        set(ax, 'DeleteFcn', @digital_delete_fcn);

        set(ax, 'YLim', [0 signal_count]);
        yticks = [];
        ylabels = [];
        for i = 1:signal_count
            yticks = [yticks i-0.5];
            ylabels = strvcat(args{i*4-1}, ylabels);
        end
        set(ax,'YTick',yticks);
        set(ax,'YTickLabel',ylabels);
        fname = strrep(strcat(num2str(clock)')', '.', '-');
        set(ax, 'Tag', fname);
        if (exist('digital_data', 'dir') == 0)  
            mkdir('digital_data');
        end
        save(['digital_data/' fname], 'args'); 
    end
        
    for i = 1:signal_count
       ll_digital(signal_count-i+1, args{i*4-3}, args{i*4-2}, args{i*4}, times) 
    end

end

function [  ] = ll_digital(id, timetable, matrix, base, times)
%DIGITAL Function draws digital signal
%   function draws digital signal on current axes or new 
%   axes. 
% id is y-position of graph
% timetable is array of time marks
% matrix is array of values
% base is char, describing a base (bin, oct, dec, hex, added )
% times is array of [start_time, end_time], sets h-position and zoom

%% Setting global data

% gl is used in @draw_shape
global gl;
gl.mode = base;
gl.start_time = times(1);
gl.end_time = times(2);
gl.id = id;
start_time = times(1);
end_time = times(2);

%% Intellectual algoritm. Process timetable

%interval which must be displayed divides into 1000 subintervals
% for each subinterval we found a_point and b_point, which are indexes of
% first and last point of matrix in this subinterval;

%initializing
a_points = zeros(1, 1000);
b_points = zeros(1, 1000);
dt = (end_time - start_time) / 1000;

%stack for recursion.
rec_mx = zeros(1, 200);
rec_index = 1;
rec_mx(1) = 1;
rec_mx(2) = size(matrix, 2);
if (rec_mx(2) < 2)
  error 'not enough points';
end
%index of subintervals, in which first and last points are
first_point_interval = floor((timetable(1) - start_time) / dt);
last_point_interval = floor((timetable(rec_mx(2)) - start_time) / dt);
if(last_point_interval<0)       %If interval is out of range then changing it to 0, to prevent error while filling a_points with -1
   last_point_interval = 0;
end

rec_mx(3) = first_point_interval;
rec_mx(4) = last_point_interval;

%filling subintervals without points (at the start and the end) with -1
for i = 1:rec_mx(3)-1
  a_points(i) = -1;
end

for i = rec_mx(4) + 1:1000
  a_points(i) = -1;
end

%these 2 points are processed separately
if ((first_point_interval > 0) && (first_point_interval < 1001))
    a_points(first_point_interval) = 1;
end
if ((last_point_interval > 0) && (last_point_interval < 1001))
    b_points(last_point_interval) = size(matrix, 2);
end

% recursion
% on each step a piece of timetible, first and last points of which are
% lying in differents subintervals, is divided in two pieces, this
% operations repeates until these points becomes adjacent or lying in same
% subinterval
while (rec_index > 0)
  p1 = rec_mx(rec_index * 4 - 3);
  p2 = rec_mx(rec_index * 4 - 2);
  a = rec_mx(rec_index * 4 - 1);
  b = rec_mx(rec_index * 4);
  if (a == b)
    rec_index = rec_index - 1;
  elseif (p2 - p1 == 1)
    if (b > a)
      for i = max([a 1]):min([b 1001]-1)
        b_points(i) = p1;
      end
      for i = max([a 0])+1:min([b 1000])
        a_points(i) = p2;
      end
    end
    rec_index = rec_index - 1;
  else
    p3 = fix((p1 + p2) / 2);
    c = fix((timetable(p3) - start_time) / dt);
    rec_index = rec_index - 1;
    if (c > 0)
      rec_mx(rec_index * 4 + 1) = p1;
      rec_mx(rec_index * 4 + 2) = p3;
      rec_mx(rec_index * 4 + 3) = a;
      rec_mx(rec_index * 4 + 4) = c;
      rec_index = rec_index + 1;
    end
    if (c < 1001)
      rec_mx(rec_index * 4 + 1) = p3;
      rec_mx(rec_index * 4 + 2) = p2;
      rec_mx(rec_index * 4 + 3) = c;
      rec_mx(rec_index * 4 + 4) = b;
      rec_index = rec_index + 1;
    end
  end
end

%% Fill values and states tables

%values_mx is values of signal on each of subintervals
values_mx = zeros(1, 1000,class(matrix));

%state_mx is states of signal on each of subintervals
state_mx = zeros(1, 1000);

%states:
%0 = no data
%1 = no points
%2 = no signal change
%3 = 1 signal change
%4 = many signal changes
last_value = NaN;
for i = 1:1000
    %determine for each point state of signal
  if (a_points(i) == -1)
    state_mx(i) = 0;
  elseif (a_points(i) > b_points(i)) 
    state_mx(i) = 1;
    values_mx(i) = matrix(b_points(i));
    if (isnan(last_value))
        last_value = matrix(b_points(i));
    end
  else
    if (isnan(last_value))
        last_value = matrix(b_points(i));
    end
    last_val = matrix(a_points(i));
    %if on subinterval there are more than 1 point count changes of signal
    changes = 0;
    for j = a_points(i) + 1:b_points(i)
      if (matrix(j) ~= last_val)
        changes = changes + 1;
        last_val = matrix(j);
      end
      if (changes > 1)
        break;
      end
    end
    state_mx(i) = 2 + changes;
    values_mx(i) = last_val;
  end
end


%% drawing

block_start = 1;
for i = 1:1000
  switch state_mx(i)
    case 0 
      % no data
      if (block_start < i)
        draw_shape(block_start, i-1, last_value, true)
      end
      block_start = i + 1;
      if (i < 1000)
          last_value = values_mx(i + 1);
      end
    case 2
      %no signal change. Draw block if previous and current values are
      %different
      if (last_value ~= values_mx(i))
        draw_shape(block_start, i, last_value, false)
        block_start = i + 1;
        last_value = values_mx(i);
      end
    case 3
      %signal changes once. Draw block
      if (block_start < i)
        draw_shape(block_start, i-1, last_value, false);
      end
      block_start = i;
      last_value = matrix(b_points(i));
    case 4
      %signal changes many times. Draw gray block;
      if (block_start < i)
        draw_shape(block_start, i-1, last_value, false);
      end
      draw_shape(i, i, 0, false);
      block_start = i+1;
      last_value = matrix(b_points(i));
  end
end

%drawing last block
if (block_start < 1001)
  draw_shape(block_start, 1000, last_value, true);
end


end

function [val] = value2text(value, template)
  template_copy = template;
  % parse template
 try
    if (template(1) == 'f')                 %Floating point numbers
        signed = 0;
        template = template(2:end);
        if (~isempty(template))  %if no base discription then signed
            switch template(1)
                case 's'         %Single
                    base='s';
                case 'd'         %Double
                    base='f';
                case 'c'         %Custom
                    base='c';
                otherwise
                    base='f';    %By default double
            end
            template = template(2:end);
        else
            base='f';                       %by default floating point numbers are double
        end
    else                                    %Fixed point and integer numbers
        signed = 0;
        if (template(1) == 's')
            signed = 1;
            template = template(2:end);
        end
        if (~isempty(template))  %if no base discription then signed
            base = template(1);
        else
            base = 'd';
        end
        template = template(2:end);
    end
    
    if (~isempty(template))
        pos = strfind(template, '.');
        if (~isempty(pos))
            int_size = str2num(template(1:pos(1) - 1));
            float_size = str2num(template(pos(1) + 1:end));
        else
            int_size = str2num(template);
            float_size = 0;
        end
    else
        if (signed == 1)
            int_size = 63;
        else
            int_size = 64;
        end
        float_size = 0;
    end
  catch %#ok
      error(['Invalid template: ' template_copy]);
  end
  
  if ((base ~= 'f') && (base ~= 's') && (base ~= 'c') && ...
      (base ~= 'h') && (base ~= 'd') && (base ~= 'o') && (base ~= 'b'))
      error(['Invalid template: ' template_copy]);
  end
  
%   signed = 1;
%   float_size = 3; % number of bits after comma
%   int_size = 5; % number of bits before comma (excluding sign bit)
%   base = 'h'; 
  
  % convert to uint64
  tmp = int64(value);
  u_big = typecast(tmp, 'uint64');
  
  if (signed == 1)
      sign_part = bitshift(u_big, -(int_size + float_size));
  else
      sign_part = uint64(0);
  end
  
  sign = 0;
  
  if (sign_part == 1)
      sign = 1;
      mask = bitshift(uint64(1), int_size + float_size) - 1;
      u_big = bitxor(bitand(u_big, mask), mask) + 1;
  elseif (sign_part ~= 0)
      sign = 2;
  end
  
  int_part = bitshift(u_big, -float_size);
  float_part = u_big - bitshift(int_part, float_size);
  
  if (sign == 2)
      val = 'ovf';
  else
      float_str = '';
      switch base
        case 'h'
          int_str = ['h' dec2hex(int_part)];
          if (float_size > 0)
            desired_len = ceil(float_size / 4);
            float_part = bitshift(float_part, 4 * desired_len - float_size);            
            tmp = dec2hex(float_part);
            float_str = ['.' repmat('0', 1, desired_len - length(tmp)), tmp];
          end
        case 'b'
          int_str = ['b' dec2bin(int_part)];
          if (float_size > 0)
            tmp = dec2bin(float_part);
            float_str = ['.' repmat('0', 1, float_size - length(tmp)), tmp];
          end
        case 'o'
          int_str = ['o' dec2base(int_part, 8)];
          if (float_size > 0)
            desired_len = ceil(float_size / 3);
            float_part = bitshift(float_part, 3 * desired_len - float_size);            
            tmp = dec2base(float_part, 8);
            float_str = ['.' repmat('0', 1, desired_len - length(tmp)), tmp];
          end
        case 'f'
            sign=0;
            td=typecast(value,'double');
            float_str=0;
            int_str=num2str(td);   
        case 's'
            sign=0;
            td=typecast(tmp,'single');
            float_str=0;
            int_str=num2str(td(1));   
        case 'c'
            sign=0;
            td=custom2float(tmp,int_size,float_size);
            float_str=0;
            int_str=num2str(td(1));   
        otherwise
          int_str = ['d' num2str(int_part)];
          if (float_size > 0)
              tmp = num2str(float_part * 5^float_size);
            float_str = ['.' repmat('0', 1, float_size - length(tmp)), tmp];
          end
      end
      if (sign == 1)
          val = '-';
      else
          val = '';
      end
      val = [val int_str float_str];
  end
end

function draw_shape(x1, x2, value, sqaure_end)
global gl;
    y = gl.id - 1;
    % slope width for hexagons
    slope_w = 10;
    
    %0.001 of width of axes
    point_w = (gl.end_time - gl.start_time) / 1000;
    
    d = slope_w * point_w;

    %coordinates transformation
    x1 = gl.start_time + (x1 * (gl.end_time - gl.start_time) / 1000);
    x2 = gl.start_time + (x2 * (gl.end_time - gl.start_time) / 1000);
    
    %if hexagon is enough wide
    if (x2 - x1 >= 2 * d)
       %draw hexagon
      line([x1   x1+d], [y+0.5 y+0.1]);
      line([x1   x1+d], [y+0.5 y+0.9]);
      if (~sqaure_end)
        line([x1+d x2-d], [y+0.1 y+0.1]);
        line([x1+d x2-d], [y+0.9 y+0.9]);
        line([x2-d x2  ], [y+0.1 y+0.5]);
        line([x2-d x2  ], [y+0.9 y+0.5]);
      else
        line([x1+d x2], [y+0.1 y+0.1]);
        line([x1+d x2], [y+0.9 y+0.9]);
        line([x2 x2  ], [y+0.1 y+0.9]);
      end
      %draw text
      val = value2text(value, gl.mode);
      %if text don't fit, delete it
      t = text((x1 + x2) / 2, y+0.5, val, 'HorizontalAlignment', ...
        'center', 'Color', 'b');
      bnd = get(t, 'Extent');
      if (bnd(3) > x2 - x1 - d) 
        delete(t);
      end
    else
      %if hexagon is too narrow, draw gray line instead of it
      rectangle('Position', [x1 y+0.1 x2 - x1 + point_w 0.8], 'EdgeColor', ...
        [0.5 0.5 0.5], 'FaceColor', [0.5 0.5 0.5]);
    end
end

