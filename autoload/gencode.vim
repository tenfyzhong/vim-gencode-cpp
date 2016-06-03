"==============================================================
"    file: gencode.vim
"   brief: 
" VIM Version: 7.4
"  author: tenfyzhong
"   email: 364755805@qq.com
" created: 2016-06-03 14:34:41
"==============================================================

function! s:ConstructIndentLine(content) "{{{
    let l:returnContent = a:content
    if &expandtab
        let l:returnContent = repeat(' ', &tabstop) . l:returnContent
    else
        let l:returnContent = '	' . l:returnContent
        let l:returnContent = substitute(l:returnContent, ' ', '\t', '')
    endif
    return l:returnContent
endfunction "}}}

function! s:ConstructReturnContent(returnContent) "{{{
    let l:returnContent = 'return ' . a:returnContent . ';'
    return <SID>ConstructIndentLine(l:returnContent)
endfunction "}}}

function! gencode#GenDefinition() "{{{
    let l:curline = line('.')
    let l:defineEndLine = search(';', 'n')
    if l:defineEndLine == 0
        let l:defineEndLine = l:curline
    endif

    let l:lineContentList = getline(l:curline, l:defineEndLine)
    let l:lineContent = join(l:lineContentList, '\n')
    let l:isInline    = match(l:lineContent, 'inline') != -1
    " remove virtual, static, explicit key word
    let l:lineContent = substitute(l:lineContent, '\%(virtual\|static\|explicit\|inline\)\s\+', '', 'g')
    let l:lineContent = substitute(l:lineContent, '^\s\+', '', '') " delete header space
    let l:lineContent = substitute(l:lineContent, '\(\w\+\)\s*\(\*\|&\+\)\s*\(\w\+\)', '\1\2 \3', '')  " format to: int* func(...);
    let l:lineContent = substitute(l:lineContent, '\s\s\+', ' ', 'g') " delete more space

    " get class content
    let l:classLine = search('\<class\>\|\<struct\>', 'b')
    let l:classLineLeftBraces = search('{', 'n')
    let l:classLineContentList = getline(l:classLine, l:classLineLeftBraces)
    let l:classLineContent = join(l:classLineContentList, ' ')
    if strlen(l:classLineContent) > 0
        let l:className = matchlist(l:classLineContent, '\(\<class\>\|\<struct\>\)\s\+\(\w[a-zA-Z0-9_]*\)')[2]
        let l:lineContentMatchList = matchlist(l:lineContent, '\(\%(\%(\w[a-zA-Z0-9_:*&]*\)\s\)\+\)\(\~\?\w[a-zA-Z0-9_]*\s*\((\?.*)\)\?\s*\%(const\)\?\);') " match function declare, \1 match return type, \2 match function name and argument, \3 match argument
        let l:lineContent = l:lineContentMatchList[1] . l:className  . '::' . l:lineContentMatchList[2]

        if empty(l:lineContentMatchList[3])
            " if is variable, contact ';
            let l:lineContent = l:lineContent . ';'
        endif
        let l:returnType = substitute(l:lineContentMatchList[1], '^\s*\(.*\S\)\s*$', '\1', '')
    endif

    " if header file, change to source file
    let l:fileExtend = expand('%:e')
    if !l:isInline && l:fileExtend ==? 'h'
        try
            exec ':A'
        catch
        endtry
    endif

    " if definition existed, finish
    let l:pos = getpos('.')
    call cursor(0, 0)
    let l:searchResult = search('\V' . l:lineContent)
    if l:searchResult > 0
        echom l:lineContent . ' has exist'
        return
    endif

    let l:appendLine = line('$')
    let l:fileExtend = expand('%:e')
    " if in header file, set the append line before the '#endif' line
    if l:fileExtend ==? 'h'
        call cursor(l:appendLine, 0)
        let l:appendLine = search('#endif', 'b')
        if l:appendLine > 0
            let l:appendLine = l:appendLine - 1
        endif
    endif

    let l:appendLineContent = getline(l:appendLine)

    let l:appendContent = []

    " insert a blank line 
    if l:appendLineContent !~ '^\s*$'
        call add(l:appendContent, '')
    endif

    call add(l:appendContent, l:lineContent)

    if l:lineContent =~ '(.*)'
        call add(l:appendContent, '{')

        if exists("g:cpp_gencode_function_attach_statement")
            for statement in g:cpp_gencode_function_attach_statement
                call add(l:appendContent, <SID>ConstructIndentLine(statement))
            endfor
        endif

        if l:returnType == 'bool'
            call add(l:appendContent, <SID>ConstructReturnContent('true'));
        elseif l:returnType =~ 'char'
            call add(l:appendContent, <SID>ConstructReturnContent("''"));
        elseif l:returnType =~ 'int\|unsigned\|long\|char\|uint\|short\|float\|double'
            call add(l:appendContent, <SID>ConstructReturnContent('0'))
        elseif l:returnType == 'void'
            " empty
        elseif l:returnType =~ '\*'
            call add(l:appendContent, <SID>ConstructReturnContent('NULL'))
        elseif strlen(l:returnType) > 0
            call add(l:appendContent, <SID>ConstructReturnContent(l:returnType . '()'))
        endif
        call add(l:appendContent, '}')
    endif

    call add(l:appendContent, '')
    call append(l:appendLine, l:appendContent)
    call cursor(l:appendLine + 1, 0)
endfunction "}}}

