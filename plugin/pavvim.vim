" Author: awlayton <alex@layton.in>
" Description: Add functions for sending Pavlok stimuli

if exists('s:loaded')
    finish
endif
let s:loaded = 1

let s:auth_url = 'http://pavlok-mvp.herokuapp.com/oauth/authorize'
let s:token_url = 'http://pavlok-mvp.herokuapp.com/oauth/token'
let g:pavvim#redirect_uri = 'urn:ietf:wg:oauth:2.0:oob'
let g:pavvim#default_message = 'pavvim'
let g:pavvim#tokfile = expand('~/.vim/pavvim_token')

function pavvim#gettoken()
    if exists('g:pavvim#token')
        return
    endif

    if filereadable(g:pavvim#tokfile)
        let g:pavvim#token = join(readfile(g:pavvim#tokfile))
    else
        let l:url = s:auth_url .
            \ '?client_id=' . g:pavvim#client_id .
            \ '&redirect_uri=' . g:pavvim#redirect_uri .
            \ '&response_type=code'
        call system('xdg-open ''' . l:url . '''')
        let l:code = inputdialog('Enter Pavlok Authorization Code:')

        let l:params = {}
        let l:params.client_id = g:pavvim#client_id
        let l:params.client_secret = g:pavvim#client_secret
        let l:params.code = l:code
        let l:params.grant_type = 'authorization_code'
        let l:params.redirect_uri = g:pavvim#redirect_uri
        let l:ctx = webapi#http#post(s:token_url, l:params)

        if l:ctx.status == 200
            let g:pavvim#token = webapi#json#decode(l:ctx.content).access_token
            call writefile([g:pavvim#token], g:pavvim#tokfile)
        else
            echoe l:ctx.content
        endif
    endif
endfunction

" TODO: Handle token expiry
function pavvim#losetoken()
endfunction

let s:api_url = 'http://pavlok-mvp.herokuapp.com/api/v1/'
function pavvim#stimulus(stimulus, value, ...)
    call pavvim#gettoken()
    let l:message = a:0 >= 1 ? a:1 : g:pavvim#default_message
    let l:url = s:api_url . 'stimuli/' . a:stimulus . '/' . a:value
    let l:body = {'reason': l:message}
    let l:headers = {'authorization': 'Bearer ' . g:pavvim#token}
    call webapi#http#post(l:url, l:body, l:headers)
    return ''
endfunction

function pavvim#vibrate(value, ...)
    if a:0 >= 1
        return pavvim#stimulus('vibration', a:value, a:1)
    else
        return pavvim#stimulus('vibration', a:value)
    endif
endfunction
function pavvim#zap(value, ...)
    if a:0 >= 1
        return pavvim#stimulus('shock', a:value, a:1)
    else
        return pavvim#stimulus('shock', a:value)
    endif
endfunction
function pavvim#beep(value, ...)
    if a:0 >= 1
        return pavvim#stimulus('beep', a:value, a:1)
    else
        return pavvim#stimulus('beep', a:value)
    endif
endfunction
function pavvim#led(value, ...)
    if a:0 >= 1
        return pavvim#stimulus('led', a:value, a:1)
    else
        return pavvim#stimulus('led', a:value)
    endif
endfunction
