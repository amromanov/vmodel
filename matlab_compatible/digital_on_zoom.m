%%*********************vmodel MATLAB Verilog simulator******************
%%Moscow, Control Problems Department MIREA, 2009-2011
%%Authors: Karyakin D, Romanov A
%%- 
%%Distributed under the GNU LGPL
%%**********************************************************************

function digital_on_zoom(obj,evd)
%callback function for zoom event

    %get file with stored parameters of 'digital'
    fname = get(evd.Axes, 'Tag');
    args = load(['digital_data/' fname]);
    
    %zoom value is stored in axes 'XLim' property
    lims = get(evd.Axes, 'XLim');
    
    %redraw
    % str to eval = 'digital(args.args{1}, args.args{2}, ... args.args{n}, lims);'
    str_to_eval = 'digital(''+'', ';
    for i = 1:size(args.args, 2)
        str_to_eval = [str_to_eval 'args.args{' int2str(i) '}, '];
    end
    str_to_eval = [str_to_eval 'lims);'];
    
    eval(str_to_eval);
end

