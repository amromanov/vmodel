function [ err_cnt_o, err_list_o ] = add_test_res( err_cnt, err_list, id,  exp )
    err_cnt_o=err_cnt+exp;
    if(err_cnt_o~=err_cnt)
        err_list_o=[err_list; id];
    else
        err_list_o=err_list;
    end
end

