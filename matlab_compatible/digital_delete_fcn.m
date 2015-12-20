%%*********************vmodel MATLAB Verilog simulator******************
%%Moscow, Control Problems Department MIREA, 2009-2011
%%Authors: Karyakin D, Romanov A
%%- 
%%Distributed under the GNU LGPL
%%**********************************************************************

function digital_delete_fcn(src, eventdata)
    %function deletes *.mat file, corresponding with axes object
    fname = get(src, 'Tag');
    delete(['digital_data/' fname '.mat']);
end

