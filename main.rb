require_relative './comicpub'

def main   
    puts("No cbz/rar/folder provided") || exit(1) if ARGV.length == 0

    create_epub(ARGV[0])
end

main
