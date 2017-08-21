if !exists('g:vim_http_clean_before_do')
  let g:vim_http_clean_before_do = 1
endif
if !exists('g:vim_http_additional_curl_args')
  let g:vim_http_additional_curl_args = ''
endif
if !exists('g:vim_http_split_vertically')
  let g:vim_http_split_vertically = 0
endif

command! -bang Http call http#do_buffer('<bang>' == '!')
command! -bang HttpShowCurl call http#show_curl('<bang>' == '!')
command! -bang HttpShowRequest call http#show_request('<bang>' == '!')
command! HttpClean call http#clean()
command! HttpAuth call http#auth()
