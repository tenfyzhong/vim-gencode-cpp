"==============================================================
"    file: gencode.vim
"   brief: 
" VIM Version: 7.4
"  author: tenfyzhong
"   email: 364755805@qq.com
" created: 2016-06-03 14:34:41
"==============================================================

function! gencode#ConstructIndentLine(content) "{{{
    let l:returnContent = a:content
    if &expandtab
        let l:returnContent = repeat(' ', &tabstop) . l:returnContent
    else
        let l:returnContent = '	' . l:returnContent
        let l:returnContent = substitute(l:returnContent, ' ', '\t', '')
    endif
    return l:returnContent
endfunction "}}}


function! s:GetClassLine(className) "{{{
    let l:classLine = search('class\_\s\+' . a:className, 'b')

    if l:classLine == 0
        let l:fileExtend = expand('%:e')
        if l:fileExtend ==? 'h'
            " if already in header file, return 
            return l:classLine
        endif

        " in source file
        try
            exec ':A'
        catch
        endtry

        call cursor(0, 0)
        let l:classLine = search('class\_\s\+' . a:className)

        if l:classLine == 0
            return l:classLine
        endif
    endif

    return l:classLine
endfunction "}}}

function! gencode#GenDeclaration() "{{{
    let l:curline = line('.')
    let l:functionLeftBraces = search('{', 'n')
    if l:functionLeftBraces == 0
        let l:functionLeftBraces = l:curline
    endif

    let l:functionDeclareList = getline(l:curline, l:functionLeftBraces)
    let l:functionDeclare = join(l:functionDeclareList, '\n')
    let l:functionDeclare = substitute(l:functionDeclare, '\s\s+', ' ', 'g')
    let l:functionDeclare = substitute(l:functionDeclare, '\(\w\+\)\s*\(\*\|&\+\)\s*\(\w\+\)', '\1\2 \3', '')  " format to: int* func(...);
    let l:functionMatchList = matchlist(l:functionDeclare, '\(\%(\%(\w[a-zA-Z0-9_:*&]*\)\s\)\+\)\(\w[a-zA-Z0-9_]*\)\s*::\s*\(\S\+\s*(.*)\s*\%(const\)\?\)') " \1 match return type, \2 match class name, \3 match function name and argument
    let l:returnType = l:functionMatchList[1]
    let l:className = l:functionMatchList[2]
    let l:functionName = l:functionMatchList[3]

    let l:classLine = <SID>GetClassLine(l:className)
    if l:classLine == 0
        return
    endif

    " jump to '}' of the class
    normal ][
    let l:appendLine = line('.') - 1

    let l:appendContent = l:returnType . l:functionName . ';'

    let l:findLine = search(l:appendContent, 'bn', l:classLine)
    if l:findLine > 0
        call cursor(l:findLine - 1, 0)
        echom l:appendContent . ' existed'
        return
    endif

    call append(l:appendLine, gencode#ConstructIndentLine(l:appendContent))
    call cursor(l:findLine - 1, 0)
endfunction "}}}
