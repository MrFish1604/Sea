function sea
    switch $argv[1]
    case 'help'
        echo 'Usage: sea [function] [name] [options]'
        echo '  new [name] [options]'
        echo '    -d, --directories: create src and include directories'
        echo '    -H, --header: create a header file'
        echo '    -g, --git: create a git repository'
        echo '    -l, --lang: specify the language (c or c++)'
        echo '    -c, --compiler: specify the compiler (default: gcc for c, g++ for c++)'
        echo '    -m, --makefile: create a makefile'
        echo '  add [name] [options]'
        echo '    -H, --header: create a header file'
        echo '    -l, --lang: specify the language (c or c++)'
        echo '  reset: reset the current project with new options'
    case 'add'
        if not argparse 'H/header' 'l/lang=' -- $argv or not $argv[2]
            sea help
            return
        end
        set -l lang 'c'
        if set -q _flag_lang
            set lang $_flag_lang
        end
        if test -d "src/"
            set path "src/$argv[2].$lang"
        else
            set path "$argv[2].$lang"
        end
        touch $path
        if set -q _flag_header
            if test -d "include/"
                set ipath "include/$argv[2].h"
            else
                set ipath "$argv[2].h"
            end
            echo -e "#ifndef $(string upper $argv[2])_H\n#define $(string upper $argv[2])_H\n\n#endif" > $ipath
            echo -e "#include \"$argv[2].h\"\n" > $path
        end
        if test -f "Makefile"
            set -l content $(string split " " (cat "Makefile"))
            if contains "bin:" $content
                set -f output "\nbin/$argv[2].o: bin"
            else
                set -f output "\n$argv[2].o:"
            end
            set -a output "\n\t\$(CC) \$(CFLAGS) -c $path -o \$@"
            echo $output
            echo -e "$output" >> Makefile
        end
    case 'new'
        if not argparse 'd/directories' 'H/header' 'g/git' 'l/lang=' 'c/compiler=' 'm/makefile' -- $argv or not $argv[2]
            sea help
            return
        end
        set -l name $argv[2]
        set -l fname (string lower $name)
        echo "Creating project $name"
        if test "$name" != "$(basename $PWD)"
            mkdir -p $name
            cd $name
        end
        set -l lang 'c'
        if set -q _flag_lang
            set lang $_flag_lang
        end
        if set -q _flag_compiler
            set -f compiler $_flag_compiler
        else
            if test "$lang" = 'c++'
                set -f compiler 'g++'
            else
                set -f compiler 'gcc'
            end
        end
        if set -q _flag_directories
            mkdir -p "src"
            mkdir -p "include"
            set -f path "src/$fname.$lang"
            if set -q _flag_header
                set -f ipath "include/$fname.h"
            end
        else
            set -f path "$fname.$lang"
            if set -q _flag_header
                set -f ipath "$fname.h"
            end
        end
        touch $path
        echo "$path created"
        if set -q ipath
            echo -e "#ifndef $(string upper $fname)_H\n#define $(string upper $fname)_H\n\n#endif" > $ipath
            echo -e "#include \"$fname.h\"\n" > $path
        end
        if set -q _flag_makefile
            set -l makecontent "CC=$compiler\nCFLAGS=-Wall -Wextra -pedantic -fdiagnostics-color=always -O0 -g3 -fsanitize=address"
            if set -q _flag_directories
                set -a makecontent "\nCFLAGS+=-Iinclude"
                set -f output "bin/$fname.o"
                set -f req "bin"
            else
                set -f output "$fname.o"
                set -f req ""
            end
            set -a makecontent "\n\n$output: $req\n\t\$(CC) \$(CFLAGS) -c $path -o \$@"
            if set -q _flag_directories
                set -a makecontent "\n\nbin:\n\tmkdir -p bin"
            end
            echo -e $makecontent > Makefile
        end
        if set -q _flag_git
            git init
            echo -e "bin/\n*.o" > .gitignore
            git add * .gitignore
            git commit -m "Initial commit"
        end
    case 'reset'
        set -l name (basename $PWD)
        read -P "Are you sure you want to reset '$name'? (y/N) " -n 1 choice
        if test "$choice" = "y"
            rm -rf *
            echo "Content of $name deleted"
            cd ..
            sea new $name $argv
        end
    case '*'
        echo 'Usage: sea [new]'
    end
end