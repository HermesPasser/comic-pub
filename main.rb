require_relative './comicpub'
require 'optparse'

$verbosity_level = 1

def log(text, level)
    puts text if $verbosity_level >= level
end

def kill_if(text, condition=true)
    return if !condition
    puts(text)
    exit(1)
end

def validate_output_file(path)
    path = Pathname.new(path)
    kill_if('The output file path is not a file', path.directory?)
    kill_if('The output file folder must be valid and exists', !Dir.exists?(path.dirname))
    path
end

def parse_args
    options = {}
    OptionParser.new do |opt|
        # handle optional args
        opt.banner = "Usage: main.rb <folder or cbz/zip> [options]\n\n"
        
        opt.on("-v", "--verbose LEVEL", Integer, "How detailed is the logging") { |v| $verbosity_level = v }
        opt.on("-o", "--output FILE", "Set non default output epub file location") { |o| options[:output] = validate_output_file(o) }
        opt.on("-h", "--help", "Prints this message") { |o| kill_if(opt.help) }
    end.parse!

    # handle positional args
    options[:filename] = fname = ARGV.pop
    kill_if("No cbz/rar/folder provided", fname == nil)
    kill_if("cbz/rar/folder does not exists", !File.exists?(fname) && !Dir.exists?(fname))
    options

rescue OptionParser::InvalidOption => e
    kill_if "\n#{e}. Use -h for help"
end

def main
    puts("Comic pub 0.1 - The poor man's comic to epub converter.\nBy Douglas S. Lacerda <hermespaser@gmail.com> under GPLv3")
    ops = parse_args

    epub_name = create_epub(ops)
end

main
