# vim-gencode-cpp
auto generate function definition or declaration  

# Features
- generate the function definitions of class  
- generate the static variable definitions of class  
- generate the declaration of the function

# Install
*windows* users change all occurrencws of `~/.vim` to `~\vimfiles`.  
- You can choose you preferred bundle manager   
- Run the following commans in a terminal:  
```bash
mkdir -p ~/.vim/bundle  
cd ~/.vim/bundle  
git clone https://github.com/tenfyzhong/vim-gencode-cpp.git  
echo 'set runtimepath^=~/.vim/bundle/vim-gencode-cpp' >> ~/.vimrc  
```

# Usage
run `GenDefinition` in a function or variable declared  
run `GenDeclaration` in a definition of a function

# Configuration
`g:cpp_gencode_function_attach_statement`  
A list of statement, this will be insert into function body before the function return.  
default:   
```viml
let g:cpp_gencode_function_attach_statement = []
```
sample:  
```viml
let g:cpp_gencode_function_attach_statement = ['std::cout << "function body"' << std::endl;']
```
it generate definition like this:  
```cpp
int Foo::function()
{
    std::cout << "function body" << std::endl;
    return 0;
}
```

`g:cpp_gencode_inlines_file_mode`
Set inline file usage mode.  The valid options are:
- 'auto' - Use inlines file if one exists.  Otherwise use header file (default).
- 'always' - Use inlines file if one exists.  Otherwise create one using the first suffix in `g:cpp_gencode_inlines_file_suffix`.
- 'never' - Disables all inline file support.

`g:cpp_gencode_inlines_file_suffix`
Comma separated list of valid inlines file suffixes.

Default:
```let g:cpp_gencode_inlines_file_suffix = '.inl'```

*Note:* The suffix must include the dot character.  This allows suffixes that include the file name to be supported e.g. `foo_inlines.h`

# Dependency
- [a.vim](https://github.com/vim-scripts/a.vim)

# TODO
