[![CircleCI](https://circleci.com/gh/nicwest/vim-http/tree/master.svg?style=svg)](https://circleci.com/gh/nicwest/vim-http/tree/master)
[![Powered by vital.vim](https://img.shields.io/badge/powered%20by-vital.vim-80273f.svg)](https://github.com/vim-jp/vital.vim)

vim-http
========

Simple wrapper over curl and http syntax highlighting.

[![asciicast](https://asciinema.org/a/120707.png)](https://asciinema.org/a/120707)


Usage
------

Write a raw http request

```http
GET http://httpbin.org/get HTTP/1.1
Host: httpbin.org
Accept: application/json
```

`:Http` will execute the request and display the response in a new buffer.

`:Http!` will execute the request as above and follow any redirects.

`:HttpShowCurl` displays the curl request that the plugin executes under the 
hood

`:HttpShowRequest` displays the internal object representing the request

`:HttpClean` will add Host and Content-Length headers

`:HttpAuth` will prompt for authorization credentials


Configuration
-------------

`g:vim_http_clean_before_do` if set to `1` (default) will clean a request before
sending it to curl. Disable this by setting this global to `0`

`g:vim_http_additional_curl_args` can be used to provide additional arguments
to curl.

`g:vim_http_split_vertically` when set to `1` will split the window vertically
on response rather than horizontally (the default).

`g:vim_http_right_below` when set to `1` split window will be open on the
right (for vertical) or below (for horizontal).

`g:vim_http_tempbuffer` when set to `1` response buffers will overwrite each
other instead of persisting forever.

Helper Methods
--------------

`http#remove_header(header)` removes all occurances of the given header in the
current buffer.

`http#set_header(header, value)` sets the header to the given value in the
current buffer, removes duplicates

Examples for your vimrc:

```viml
function! s:set_json_header() abort
  call http#set_header('Content-Type', 'application/json')
endfunction

function! s:clean_personal_stuff() abort
  call http#remove_header('Cookie')
  call http#remove_header('Accept')
  call http#remove_header('User-Agent')
  call http#remove_header('Accept-Language')
endfunction 

function! s:add_compression() abort
  call http#set_header('Accept-Encoding', 'deflate, gzip')
  if exists('g:vim_http_additional_curl_args')
    let g:vim_http_additional_curl_args .= ' --compressed'
  else
    let g:vim_http_additional_curl_args  = ' --compressed'
  endif
endfunction
function! s:remove_compression() abort
  call http#remove_header('Accept-Encoding')
  if exists('g:vim_http_additional_curl_args')
    let g:vim_http_additional_curl_args = substitute(g:vim_http_additional_curl_args, '--compressed', '', 'g')
  endif
endfunction

command!       JSON         call s:set_json_header()
command!       Anon         call s:clean_personal_stuff()
command! -bang Compression  if <bang>1|call s:add_compression()|else|call s:remove_compression()
```
