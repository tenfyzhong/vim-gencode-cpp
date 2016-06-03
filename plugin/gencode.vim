"==============================================================
"    file: gencode.vim
"   brief: 
" VIM Version: 7.4
"  author: tenfyzhong
"   email: 364755805@qq.com
" created: 2016-06-02 21:53:58
"==============================================================

if !exists(':A')
    echom 'need a.vim plugin'
    finish
endif

function! s:ConstructReturnContent(returnContent) "{{{
    let l:returnContent = 'return ' . a:returnContent . ';'
    if &expandtab
        let l:returnContent = repeat(' ', &tabstop) . l:returnContent
    else
        let l:returnContent = '	' . l:returnContent
        let l:returnContent = substitute(l:returnContent, ' ', '\t', '')
    endif
    return l:returnContent
endfunction "}}}

function! s:GenDefinition() "{{{
    let l:curline = line('.')
    let l:defineEndLine = search(';', 'n')
    if l:defineEndLine == 0
        let l:defineEndLine = l:curline
    endif

    let l:lineContentList = getline(l:curline, l:defineEndLine)
    let l:lineContent = join(l:lineContentList, '\n')
    let l:lineContent = substitute(l:lineContent, 'virtual\s\+', '', '')
    let l:lineContent = substitute(l:lineContent, 'static\s\+', '', '')
    let l:lineContent = substitute(l:lineContent, 'explicit\s\+', '', '')
    let l:isInline    = match(l:lineContent, 'inline') != -1
    let l:lineContent = substitute(l:lineContent, 'inline\s\+', '', '')
    let l:lineContent = substitute(l:lineContent, '^\s\+', '', '') " delete header space
    let l:lineContent = substitute(l:lineContent, '\(\w\+\)\s*\(\*\+\)\s*\(\w\+\)', '\1\2 \3', '')  " format to: int* func(...);
    let l:lineContent = substitute(l:lineContent, '\s\s\+', ' ', 'g') " delete more space

    let l:classLine = search('\<class\>\|\<struct\>', 'b')
    let l:classLineLeftBraces = search('{', 'n')
    let l:classLineContentList = getline(l:classLine, l:classLineLeftBraces)
    let l:classLineContent = join(l:classLineContentList, '\n')
    if strlen(l:classLineContent) > 0
        let l:className = matchlist(l:classLineContent, '\(\<class\>\|\<struct\>\)\s\+\(\w[a-zA-Z0-9_]*\)')[2]
        " let l:lineContentMatchList = matchlist(l:lineContent, '\(\w[a-zA-Z0-9_]\+\s\+\)\?\(\~\?\w[a-zA-Z0-9_]\+\s*(.*)\s*\);', '\1'.l:className.'::\2')
        " \%(\w[a-zA-Z0-9_]*\%(\s*::\)\?\)\+] \%(\s*::\)\?
        let l:lineContentMatchList = matchlist(l:lineContent, '\(\%(\%(\w[a-zA-Z0-9_:*]*\)\s\)\+\)\(\~\?\w[a-zA-Z0-9_]*\s*(.*)\s*\%(const\)\?\);')
        " echom "l:lineContentMatchList[1]: " . l:lineContentMatchList[1]
        " echom "l:lineContentMatchList[2]: " . l:lineContentMatchList[2]
        let l:lineContent = l:lineContentMatchList[1] . l:className  . '::' . l:lineContentMatchList[2]
        let l:returnType = substitute(l:lineContentMatchList[1], '^\s*\(.*\S\)\s*$', '\1', '')
    endif

    let l:fileExtend = expand('%:e')
    if !l:isInline && l:fileExtend == 'h'
        try
            exec ':A'
        catch
        endtry
    endif

    let l:pos = getpos('.')
    call cursor(0, 0)
    let l:searchResult = search('\V' . l:lineContent)
    if l:searchResult > 0
        echom l:lineContent . ' has exist'
        return
    endif


    let l:lastLineContent = getline(line('$'))
    if l:lastLineContent !~ '^\s*$'
        call append(line('$'), '')
    endif

    call append(line('$'), l:lineContent)
    call append(line('$'), '{')
    if l:returnType == 'bool'
        call append(line('$'), <SID>ConstructReturnContent('true'));
    elseif l:returnType =~ 'char'
        call append(line('$'), <SID>ConstructReturnContent("''"));
    elseif l:returnType =~ 'int\|unsigned\|long\|char\|uint\|short\|float\|double'
        call append(line('$'), <SID>ConstructReturnContent('0'))
    elseif l:returnType == 'void'
        " empty
    elseif l:returnType =~ '\*'
        call append(line('$'), <SID>ConstructReturnContent('NULL'))
    elseif strlen(l:returnType) > 0
        call append(line('$'), <SID>ConstructReturnContent(l:returnType . '()'))
    endif
    call append(line('$'), '}')
endfunction "}}}

command! GenDefinition call <SID>GenDefinition()
