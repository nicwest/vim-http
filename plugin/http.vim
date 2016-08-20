command! -bang Http call http#do_buffer('<bang>' == '!')
command! HttpShowCurl call http#show_curl()
command! HttpShowRequest call http#show_request()
