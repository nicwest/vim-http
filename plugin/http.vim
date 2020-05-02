if !exists('g:vim_http_clean_before_do')
  let g:vim_http_clean_before_do = 1
endif
if !exists('g:vim_http_additional_curl_args')
  let g:vim_http_additional_curl_args = ''
endif
if !exists('g:vim_http_split_vertically')
  let g:vim_http_split_vertically = 0
endif
if !exists('g:vim_http_tempbuffer')
  let g:vim_http_tempbuffer = 0
endif

command! -bang -range Http call http#do_buffer('<bang>', '<range>', '<line1>', '<line2>')
command! -bang -range HttpShowCurl call http#show_curl('<bang>', '<range>', '<line1>', '<line2>')
command! -bang -range HttpShowRequest call http#show_request('<bang>', '<range>', '<line1>', '<line2>')
command! HttpClean call http#clean()
command! HttpAuth call http#auth()
