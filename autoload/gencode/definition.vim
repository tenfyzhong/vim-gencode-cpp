"==============================================================
"    file: definition.vim
"   brief: 
" VIM Version: 7.4
"  author: tenfyzhong
"   email: 364755805@qq.com
" created: 2016-06-06 14:57:03
"==============================================================

function! s:ConstructReturnContent(returnContent) "{{{
    let l:returnContent = 'return ' . a:returnContent . ';'
    return gencode#ConstructIndentLine(l:returnContent)
endfunction "}}}

function! s:GetDeclaration(line) "{{{
    let l:pos = getpos('.')
    call cursor(a:line)
    let l:functionBeginLine   = a:line
    let l:functionEndLine     = search(';', 'n')
    call setpos('.', l:pos)
    if l:functionEndLine == 0
        let l:functionEndLine = l:functionBeginLine
    endif
    let l:functionList = getline(l:functionBeginLine, l:functionEndLine)
    let l:function     = join(l:functionList, '\n')
    return l:function
endfunction "}}}

function! s:IsInlineDeclaration(declaration) "{{{
    return match(a:declaration, 'inline') != -1
endfunction "}}}

function! s:FormatDeclaration(declaration) "{{{
    " remove virtual, static, explicit key word
    let l:lineContent = a:declaration
    let l:lineContent = substitute(l:lineContent, '\%(virtual\|static\|explicit\|inline\)\s\+', '', 'g')
    let l:lineContent = substitute(l:lineContent, '^\s\+', '', '') " delete header space
    let l:lineContent = substitute(l:lineContent, '\(\w\+\)\s*\(\*\|&\+\)\s*\(\w\+\)', '\1\2 \3', '')  " format to: int* func(...);
    let l:lineContent = substitute(l:lineContent, '\s\s\+', ' ', 'g') " delete more space
    return l:lineContent
endfunction "}}}

function! s:GetClassName(line) "{{{
    let l:cword = expand('<cword>')
    if l:cword !~ '{'
        return ''
    endif
    let l:classBeginLine = search('\%(\<class\>\|\<struct\>\)\_\s\+\w\+\_\s\+\%(:\%(\_\s*\w\+\)\{1,2}\)\?\_\s\+{', 'b')
    if l:classBeginLine == 0
        return ''
    endif
    let l:braceLine = search('{')
    if l:braceLine != a:line
        return ''
    endif
    let l:lineContent = getline(l:classBeginLine, a:line)
    let l:classDeclaration = join(l:lineContent, ' ')

    let l:className = matchlist(l:classDeclaration, '\(\<class\>\|\<struct\>\)\s\+\(\w[a-zA-Z0-9_]*\)')[2]
    return l:className
endfunction "}}}

function! s:GetNamespaceList(line) "{{{
    call cursor(a:line)
    normal [{
    let l:braceLine = line('.')
    if l:braceLine == a:line
        return []
    endif

    let l:classBeginLine = search('namespace\_\s\+\w\+\_\s*{', 'b')
    let l:searchBraceLine = search('{')

    if l:braceLine != l:searchBraceLine
        return []
    else
        let l:namespaceContentList = getline(l:classBeginLine, l:searchBraceLine)
        let l:namespaceContent = join(l:namespaceContentList, ' ')
        let l:namespaceName = matchlist(l:namespaceContent, 'namespace\%(\_\s\+\(\w\+\)\)\?\_\s*{')[1]
        return insert(<SID>GetNamespaceList(l:braceLine), l:namespaceName)
    endif
endfunction "}}}

function! gencode#definition#Generate() "{{{
    let l:line        = line('.')
    let l:declaration = <SID>GetDeclaration(l:line)

    let l:isInline    = <SID>IsInlineDeclaration(l:declaration)

    " if header file, change to source file
    let l:fileExtend = expand('%:e')
    let l:needChangeFile = !l:isInline && l:fileExtend ==? 'h'

    let l:formatedDeclaration  = <SID>FormatDeclaration(l:declaration)
    let l:declarationDecompose = matchlist(l:formatedDeclaration, '\(\%(\%(\w[a-zA-Z0-9_:*&]*\)\s\)\+\)\(\~\?\w[a-zA-Z0-9_]*\s*\((\?.*)\)\?\s*\%(const\)\?\);') " match function declare, \1 match return type, \2 match function name and argument, \3 match argument
    let [l:matchall, l:returnType, l:functionBody, l:argument; l:rest] = l:declarationDecompose

    " jump to previous unmatch {
    normal [{
    let l:classBraceLine = line('.')
    let l:className     = <SID>GetClassName(l:classBraceLine)

    let l:namespaceList = <SID>GetNamespaceList(l:classBraceLine)
    call cursor(l:classBraceLine, 0)

    let l:namespace = join(l:namespaceList, '::') 
    if !empty(l:namespace) && l:namespace[-2:-1] != '::'
        let l:namespace = l:namespace . '::'
    endif

    if !empty(l:className) 
        let l:lineContent = l:returnType . l:namespace . l:className . '::' . l:functionBody
    else
        let l:lineContent = l:returnType . l:namespace . l:functionBody
    endif

    if empty(l:argument)
        let l:lineContent = l:lineContent . ';'
    endif

    if l:needChangeFile
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
        echom l:lineContent . ' existd'
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
        else 
            let l:appendLine = line('$')
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
                call add(l:appendContent, gencode#ConstructIndentLine(statement))
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
