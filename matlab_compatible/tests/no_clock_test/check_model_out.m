function [ err_cnt_o, err_list_o ] = check_model_out( err_cnt, err_list, uut,  res )
    %Comparing direct input/output copying
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,1,res.in_8bit~=uut.in_8bit);
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,2,res.in_24bit~=uut.in_24bit);
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,3,res.in_64bit~=uut.in_64bit);
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,4,sum(squeeze(res.in_96bit)~=uut.in_96bit));
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,5,sum(sum(squeeze(res.in_mem_8bit)~=uut.in_mem_8bit)));
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,6,sum(sum(squeeze(res.in_mem_64bit)~=uut.in_mem_64bit)));
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,7,sum(sum(squeeze(res.in_mem_78bit)~=uut.in_mem_78bit)));
    %Checking for bit operations
    lb96=double(uut.in_8bit)+2^8*double(uut.in_24bit)+mod(double(uut.in_64bit),2^32);
    mb96=mod(double(uut.in_64bit),2^32)+floor((double(uut.in_64bit)+lb96-mod(lb96,2^32))/2^32);
    hb96=floor((double(uut.in_64bit)+mb96-mod(mb96,2^32))/2^32);
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,8,mod(lb96,2^32)~=res.out_96bit(1));
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,9,mod(mb96,2^32)~=res.out_96bit(2));
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,10,mod(hb96,2^32)~=res.out_96bit(3));
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,11,typecast(uint64(res.out_64bit),'int64')+1+int64(uut.in_64bit)~=0);
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,12,mod(double(uut.in_8bit)*(1+2^8+2^16)-double(uut.in_24bit),2^24)~=res.out_24bit);
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,13,sum(sum(squeeze(res.out_mem_78bit(:,:,10:-1:1))~=uut.in_mem_78bit)));
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,14,sum(sum(res.hidden_mem~=(mod(uut.in_mem_8bit,2^2)))));
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,15,sum(sum(res.huge_hidden_mem~=(zeros(1,4,6)))));
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,16,res.hidden_var~=(mod(double(uut.in_8bit)+1,2))); 
    err_cnt_o   = err_cnt;
    err_list_o  = err_list;
end