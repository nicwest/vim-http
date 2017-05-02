let s:suite = themis#suite('integration')
let s:assert = themis#helper('assert')

" Setup: {{{1
let s:original_buffers = filter(range(1, bufnr('$')), 'bufexists(v:val)')

function! s:suite.before_each()
    let l:current_buffers = filter(range(1, bufnr('$')), 'bufexists(v:val)')
    let l:buffers_to_wipe = filter(copy(l:current_buffers), 'index(s:original_buffers, v:val) == -1')
    for l:buffer in l:buffers_to_wipe
        execute 'bw!' . l:buffer
    endfor
endfunction

function! s:load_request_expected(name) abort
    let l:request_path = g:http_test_files . a:name . '.http'
    execute 'edit! ' . l:request_path
endfunction

function s:assert_response(name) abort
    let l:expected_path = g:http_test_files . a:name . '.expected.http'
    let l:expected = readfile(l:expected_path)
    let l:lines = getbufline(a:name . '.response.*.http', 0, '$')

    let l:bad = 0
    let l:lnr = 0
    for l:expect in l:expected
        let l:line = l:lines[l:lnr]
        if l:expect =~ '.*%%[^%]\+%%.*'
            let l:patterns = split(l:expect, '%%')
            let l:in_pattern = 0
            let l:line_index = 0 
            let l:pattern_nr = 0
            for l:pattern in l:patterns
                if l:in_pattern
                    let l:p = '\(' . substitute(l:pattern, '^\s*\([''"]\)\(.*\)\1\s*$', '\2', '') . '\)'
                    let l:pp = l:p
                    if len(l:patterns) > l:pattern_nr+1
                        let l:pp = l:p . l:patterns[l:pattern_nr+1]
                    endif
                    if l:line[l:line_index :] !~ l:pp
                        let l:bad = 1
                        break
                    endif
                    let l:line_index += len(substitute(l:line[l:line_index  :], l:pp, '\1', ''))
                    let l:in_pattern = 0
                else
                    if l:pattern != l:line[l:line_index : l:line_index + len(l:pattern)-1]
                        let l:bad = 1
                        break
                    end
                    let l:line_index += len(l:pattern)
                    let l:in_pattern = 1
                endif

                let l:pattern_nr += 1
            endfor
        else
            if l:line != l:expect
                let l:bad = 1
            endif
        endif
        if l:bad == 1
            break
        end

        let l:lnr += 1

    endfor

    if l:bad
        let l:msg = [printf('Got response for %s.http:', a:name)]
        let l:msg = l:msg + [''] + l:lines + ['', 'Expected:'] + l:expected
        throw themis#failure(msg)
    endif
endfunction

function! s:command_with_input(cmd, input)
  exe 'normal :' . a:cmd .''.join(a:input, '').''
endfunction
" }}}
" GET: {{{1
function! s:suite.simple_get()
    call s:load_request_expected('simple_get')
    Http
    call s:assert_response('simple_get')
endfunction

function! s:suite.get_with_url_params()
    call s:load_request_expected('get_url_params')
    Http
    call s:assert_response('get_url_params')
endfunction

function! s:suite.get_with_body_params()
    call s:load_request_expected('get_body_params')
    Http
    call s:assert_response('get_body_params')
endfunction

function! s:suite.redirect()
    call s:load_request_expected('redirect')
    Http
    call s:assert_response('redirect')
endfunction

function! s:suite.redirect_with_follow()
    call s:load_request_expected('redirect_follow')
    Http!
    call s:assert_response('redirect_follow')
endfunction
" }}}
" POST :{{{1
function! s:suite.post_json()
    call s:load_request_expected('post_json')
    Http!
    call s:assert_response('post_json')
endfunction

" }}}
" Clean :{{{1
function! s:suite.clean()
    call s:load_request_expected('post_incomplete')
    HttpClean
    let l:contents = getline(0, '$')
    let l:expected = ['POST http://localhost:8000/post HTTP/1.1', 
          \ 'Host: localhost:8000',
          \ 'Content-Length: 43',
          \ 'Content-Type: application/json',
          \ '',
          \ '',
          \ '{',
          \ '    "foo": "bar",',
          \ '    "lol": "beans"',
          \ '}',
          \ ]
    call s:assert.equal(l:contents, l:expected)
endfunction

function! s:suite.clean_replaces_invalid_content_length_header()
  call s:load_request_expected('post_invalid_content_length')
  call s:command_with_input('HttpClean', ['Y'])
  let l:contents = getline(0, '$')
  let l:expected = ['POST http://localhost:8000/post HTTP/1.1', 
        \ 'Host: localhost:8000',
        \ 'Content-Type: application/json',
        \ 'Content-Length: 43',
        \ '',
        \ '',
        \ '{',
        \ '    "foo": "bar",',
        \ '    "lol": "beans"',
        \ '}',
        \ ]
  call s:assert.equal(l:contents, l:expected)
endfunction

" }}}
" Auth: {{{1
function! s:suite.auth()
    call s:load_request_expected('simple_get')
    call s:command_with_input('HttpAuth', ['Bearer', 'borisjohnson', 'ijustcantwaittobeking'])
    let l:contents = getline(0, '$')
    let l:expected = ['GET http://localhost:8000/get HTTP/1.1', 
          \ 'Host: localhost:8000',
          \ 'Authorization: Bearer Ym9yaXNqb2huc29uOmlqdXN0Y2FudHdhaXR0b2Jla2luZw==',
          \ ]
    call s:assert.equal(l:contents, l:expected)
endfunction
" }}}
" Headers: {{{1
function! s:suite.remove_header()
  call s:load_request_expected('get_with_multiple_headers')
  call http#remove_header('User-Agent')
  let l:contents = getline(0, '$')
  let l:expected = ['GET http://localhost:8000/get HTTP/1.1', 
        \ 'Host: localhost:8000',
        \ 'Accept: text/html',
        \ 'Accept-Encoding: gzip, deflate',
        \ 'Accept-Language: en-US,en;q=0.5 ',
        \ 'Connection: close',
        \ 'Upgrade-Insecure-Requests: 1 ',
        \ ]
  call s:assert.equal(l:contents, l:expected)
endfunction

function! s:suite.set_header()
  call s:load_request_expected('get_with_multiple_headers')
  call http#set_header('User-Agent', 'qutebrowser/1.0.0')
  let l:contents = getline(0, '$')
  let l:expected = ['GET http://localhost:8000/get HTTP/1.1', 
        \ 'Host: localhost:8000',
        \ 'Accept: text/html',
        \ 'Accept-Encoding: gzip, deflate',
        \ 'Accept-Language: en-US,en;q=0.5 ',
        \ 'Connection: close',
        \ 'Upgrade-Insecure-Requests: 1 ',
        \ 'User-Agent: qutebrowser/1.0.0',
        \ ]
  call s:assert.equal(l:contents, l:expected)
endfunction
" }}}
" Misc: {{{1
" vim:fdm=marker
