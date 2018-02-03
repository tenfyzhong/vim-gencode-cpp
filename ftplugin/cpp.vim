"==============================================================
"    file: gencode.vim
"   brief: 
" VIM Version: 7.4
"  author: tenfyzhong
"   email: tenfy@tenfy.cn
" created: 2016-06-02 21:53:58
"==============================================================

if !exists(':A')
    echom 'need a.vim plugin'
    finish
endif

if !exists('g:cpp_gencode_inlines_file_mode')
    let g:cpp_gencode_inlines_file_mode = 'auto'
endif

if !exists('g:cpp_gencode_inlines_file_suffix')
    let g:cpp_gencode_inlines_file_suffix = '.inl'
endif

command! GenDefinition call gencode#definition#Generate()
command! GenDeclaration call gencode#declaration#Generate()
