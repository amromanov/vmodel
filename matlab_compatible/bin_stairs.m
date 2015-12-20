%BIN_STAIRS Outputs binary signals
%   call methods:
%  bin_stairs(data)
%  bin_stairs(time, data)
%  bin_stairs(data, signal_name)
%  bin_stairs(time, data, signal_name)
%  bin_stairs(time1, data1, (signal_name1), time_2, data2, (signal_name2),  ...)
%  parameters:
%  data - matrix of input data
%  time - matrix of times, must have same dimentions as data
%  signal_name - name of signal to display. Optional.

%%*********************vmodel MATLAB Verilog simulator******************
%%Moscow, Control Problems Department MIREA, 2009-2011
%%Authors: Karyakin D, Romanov A
%%- 
%%Distributed under the GNU LGPL
%%**********************************************************************

function [] = bin_stairs(varargin)

first_line = 0;

z = zoom;
setAxesZoomMotion(z,gca,'horizontal');

if (ishold == 1)
    c_lims = get(gca, 'YLim');
    c_lims(2) = c_lims(2) + 1.5;
    ylabels = get(gca, 'YTickLabel');
    yticks = get(gca, 'YTick');
else
    c_lims = [0 0];
    yticks = [];
    ylabels = [];
end

last_y = c_lims(2) / 2;


if (nargin == 1)
    times = 1:size(varargin{1}, 2);
    [last_y, ylabels, yticks] = draw_stairs(times, varargin{1}, '', '', ylabels, last_y, yticks);
elseif (nargin == 2)
    if (ischar(varargin{2}))
        times = 1:size(varargin{1}, 2);
        [last_y, ylabels, yticks] = draw_stairs(times, varargin{1}, '', varargin{2}, ylabels, last_y, yticks);
    else
        [last_y, ylabels, yticks] = draw_stairs(varargin{1}, varargin{2}, '', '', ylabels, last_y, yticks);
    end
elseif (nargin == 3)
        [last_y, ylabels, yticks] = draw_stairs(varargin{1}, varargin{2}, '', varargin{3}, ylabels, last_y, yticks);
elseif (nargin > 3)
    index = 1;
    while true
        % all_params = 1 means that there is 'signal_name' parameter
        all_params = 0;
        % last_param: count of unprocessed arguments
        last_params = nargin + 1 - index;
        if (last_params == 0)
            %no unprocessed arguments
            break;
        elseif (last_params < 2)
            error('Invalid number of params')
        elseif (last_params > 2)
            if (ischar(varargin{index+2}))
                all_params = 1;
            end
        end
        if (all_params == 1)
            [last_y, ylabels, yticks] = draw_stairs(varargin{index}, varargin{index+1} ...
                , '' , varargin{index+2}, ylabels, last_y, yticks);
            index = index + 3;
            if (first_line == 0)
                hold on;
                first_line = 1;
            end
        else
            [last_y, ylabels, yticks] = draw_stairs(varargin{index}, varargin{index+1} ...
                , '', '', ylabels, last_y, yticks);
            index = index + 2;
            if (first_line == 0)
                hold on;
                first_line = 1;
            end
        end
    end
else
    error('Invalid number of arguments');
end


low_lim = min(-0.5, c_lims(1));
high_lim = last_y * 2 - 0.5;

set(gca,'YLim', [low_lim, high_lim]);
set(gca,'YTick',yticks);
set(gca,'YTickLabel',ylabels);
hold off

z = zoom;
setAxesZoomMotion(z,gca,'horizontal');
end

function[last_y, labels, yticks] = draw_stairs(time, data, line, signame, labels, last_y, yticks)
    binmat = (double(dec2bin(data))-48);
    bitn = size(binmat, 2);
    el_n = size(binmat, 1);
    ybias = 2 * (last_y:bitn+last_y-1);
    last_y = last_y + bitn;
    ybiasmat = repmat(ybias, el_n, 1);
    stairs(time, binmat(:,end:-1:1)+ybiasmat, line);   
    if (isempty(signame))
        signame = 'bit ';
    else
        signame = [signame '.'];
    end
    for j = 1:bitn
        labels = strvcat(labels, [signame int2str(j-1)]);
    end
    yticks = [yticks ybias + 0.5];
end

