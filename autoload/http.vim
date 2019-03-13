let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#vim_http#new()
let s:Base64 = s:V.import('Data.Base64')

function! s:new_request() abort
    let l:response = { 
                \ 'method': 'GET',
                \ 'headers': {},
                \ 'uri': '',
                \ 'content': '',
                \ 'version': '1.1',
                \ 'meta': {
                \   'follow': 0,
                \   }
                \ }
    return l:response
    
endfunction

let s:pre_clean_uri_line_pattern = '^\(\a*\) \(.*\) HTTP/\([0-9.]\+\)\|$'
let s:uri_line_pattern = '^\(OPTIONS\|GET\|HEAD\|POST\|PUT\|DELETE\|TRACE\|CONNECT\|PATCH\) \(.*\) HTTP/\([0-9.]\+\)$'
let s:header_line_pattern = '^\([^:]\+\): \(.*\)$'

function! s:parse_request_buffer(buffer, pattern, follow) abort
    let l:request = s:new_request()
    if a:follow == 1
        let l:request.meta.follow = 1
    end
    
    let l:lines = getbufline(a:buffer, 0, '$')
    
    if len(l:lines) < 0 
        throw 'No lines in buffer :('
    endif

    let l:uri_line = l:lines[0]
    let l:uri_line_matches = matchlist(l:uri_line, a:pattern)

    if len(l:uri_line_matches) == 0 
        throw 'Unable to parse first line of request'
    end

    let l:request.method = l:uri_line_matches[1]
    let l:request.uri = l:uri_line_matches[2]
    let l:request.version = l:uri_line_matches[3]

    if l:request.version =~ '2.*'
      let l:request.version = '2'
    end

    let l:in_content = 0
    let l:first_content_line = 1
    for l:line in l:lines[0:]
        if l:in_content == 0 && l:line =~ '^\s*$'
            let l:in_content = 1
        end
        if l:in_content == 0
            let l:header_matches = matchlist(l:line, s:header_line_pattern)

            if len(l:header_matches) > 0
                let l:header_key = l:header_matches[1]
                let l:header_value = l:header_matches[2]
                if has_key(l:request.headers, l:header_key) == 0
                    let l:request.headers[l:header_key] = []
                endif
                let l:request.headers[l:header_key] += [l:header_value]
            endif
        else
            if l:first_content_line && l:line =~ '^\s*$'
                continue
            endif
            if l:first_content_line
                let l:first_content_line = 0
            else
                let l:request.content .= "\r\n"
            endif
            let l:request.content .= l:line
        endif
    endfor

    return l:request
endfunction

function! s:in_curl_format(request) abort
    let l:curl_fmt = 'curl%s%s%s%s %s'

    let l:flags = ' -si'

    if a:request.meta.follow == 1
        let l:flags = l:flags . 'L'
    endif

    let l:flags = l:flags.' '.g:vim_http_additional_curl_args

    let l:flags = l:flags.' --http'.a:request.version

    let l:method = printf(' -X %s', a:request.method)

    let l:url = shellescape(a:request.uri)

    let l:headers = ''

    for [l:header_key, l:header_value_list] in items(a:request.headers)
        for l:header_value in l:header_value_list
            let l:headers = l:headers .
                        \ ' -H "' .
                        \ printf('%s: %s', l:header_key, l:header_value) .
                        \ '"'
        endfor

    endfor
    
    let l:data = ''
    if len(a:request.content)
        let l:data = ' -d ' . substitute(shellescape(a:request.content), '\\\n', "\n", 'g')
    endif  

    let l:curl_request = printf(l:curl_fmt, l:flags, l:method, l:headers, l:data, l:url)

    return l:curl_request

endfunction

function! s:lines_with_header(header) abort
  let l:linenr = 1
  let l:lines = []
  while l:linenr < line('$')
    let l:line = getline(l:linenr)
    if l:line =~ '^\s*$'
      break
    endif
    if l:line =~ "^".a:header.":"
      call add(l:lines, l:linenr)
    end
    let l:linenr = l:linenr + 1
  endwhile
  return l:lines
endfunction

function! s:remove_header(header) abort
  let l:offset = 0
  for l:linenr in s:lines_with_header(a:header)
    let l:target = l:linenr - l:offset
    exe l:target."delete _"
    let l:offset = l:offset + 1
  endfor
endfunction

function! s:new_response_buffer(request_buffer, response) abort
    let l:request_buffer_name  = bufname(a:request_buffer)
    let l:buffer_name = fnamemodify(l:request_buffer_name, ":r") . '.response.' . localtime() . '.http'
    if g:vim_http_tempbuffer
      for win in range(1, winnr('$'))
        if getwinvar(win, 'vim_http_tempbuffer')
          execute win . 'windo close'
        endif
      endfor
    endif
    let l:keepalt = g:vim_http_tempbuffer ? 'keepalt ' : ''
    let l:vert = g:vim_http_split_vertically ? 'vert ' : ''
    execute l:keepalt . l:vert . 'new ' . l:buffer_name
    set ft=http
    if g:vim_http_tempbuffer
      setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nonumber
      let w:vim_http_tempbuffer = 1
    endif

    let l:response_lines = split(a:response, "\\(\r\n\\|\n\\)")

    call append(0, l:response_lines)
    norm! G"_ddgg
endfunction

function! http#do_buffer(follow) abort
    if g:vim_http_clean_before_do
      call http#clean()
    end
    let l:buffer = bufnr('')
    let l:request = s:parse_request_buffer(l:buffer, s:uri_line_pattern, a:follow)
    let l:curl = s:in_curl_format(l:request)
    let l:response = system(l:curl)
    call s:new_response_buffer(l:buffer, l:response)
endfunction

function! http#show_curl(follow) abort
    let l:buffer = bufnr('')
    let l:request = s:parse_request_buffer(l:buffer, s:uri_line_pattern, a:follow)
    let l:curl = s:in_curl_format(l:request)
    echo l:curl
endfunction

function! http#show_request(follow) abort
    let l:buffer = bufnr('')
    let l:request = s:parse_request_buffer(l:buffer, s:uri_line_pattern, a:follow)
    echo l:request
endfunction

function! http#clean() abort
  let l:buffer = bufnr('')
  let l:request = s:parse_request_buffer(l:buffer, s:pre_clean_uri_line_pattern, 0)

  " when the http proto is > 1.0 make sure we are adding a host header
  if index(['1.1', '2'], l:request.version) != -1 && !has_key(l:request.headers, 'Host')
    let l:matches = matchlist(l:request.uri, '^\([^:]\+://\)\?\([^/]\+\)')
    let l:host = l:matches[2]
    if len(l:host)
      call append(1, 'Host: ' . l:host)
    endif
  endif

  if l:request.version == ''
    call setline('.', getline('.') . ' HTTP/1.1')
  endif

  let l:content_length = len(l:request.content)

  " when we have a Content-Length header and it doesn't match the actual
  " content length
  if l:content_length && has_key(l:request.headers, 'Content-Length')
    if string(l:content_length) != l:request.headers['Content-Length'][-1]
      let l:correct = input("correct Content-Length header? [Y]/N:")
      if len(l:correct) == 0 || tolower(l:correct) != "n"
        call remove(l:request.headers, 'Content-Length')
        call s:remove_header('Content-Length')
      endif
    endif
  endif

  " when we are sending content we should add a header for the content length
  " curl is going to do this for us anyway, but it's good to be explicit
  if  l:content_length && !has_key(l:request.headers, 'Content-Length')
    call append(1 + len(l:request.headers), 'Content-Length: ' . l:content_length)
  endif
endfunction

function! http#auth() abort
  let l:buffer = bufnr('')
  let l:request = s:parse_request_buffer(l:buffer, s:uri_line_pattern, 0)

  let l:method = input('method [Basic]: ')
  if len(l:method) == 0
    let l:method = 'Basic'
  end
  let l:user = input('user: ')
  let l:password = input('password: ')
  let l:encoded = s:Base64.encode(l:user . ':' . l:password)
  let l:header = 'Authorization: ' . l:method . ' ' . l:encoded
  call append(1 + len(l:request.headers), l:header)
endfunction

function! http#remove_header(header) abort
  call s:remove_header(a:header)
endfunction

function! http#set_header(header, value) abort
  call s:remove_header(a:header)
  let l:buffer = bufnr('')
  let l:request = s:parse_request_buffer(l:buffer, s:uri_line_pattern, 0)
  call append(1 + len(l:request.headers), a:header.': '.a:value)
endfunction

" Teardown:{{{1
let &cpo = s:save_cpo
