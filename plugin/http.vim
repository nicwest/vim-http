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

function! s:do(bang, range, line1, line2) abort
  let l:follow = a:bang == '!'
  if a:range == 2
    call http#do_lines(l:follow, a:line1, a:line2)
  elseif a:range == 1
    throw 'Cowardly refusing to execute multiple times'
  else
    call http#do_buffer(l:follow)
  endif
endfunction

command! -bang -range Http call s:do('<bang>', '<range>', '<line1>', '<line2>')
command! -bang -range HttpShowCurl call http#show_curl('<bang>' == '!', '<range>', '<line1>', '<line2>')
command! -bang -range HttpShowRequest call http#show_request('<bang>' == '!', '<range>', '<line1>', '<line2>')
command! HttpClean call http#clean()
command! HttpAuth call http#auth()
