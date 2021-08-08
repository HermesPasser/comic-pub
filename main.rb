require_relative './comicpub'
require 'optparse'

$verbosity_level = 1
$local_temp_dir = false

def temp_dir
    if $local_temp_dir 
        dir = File.join(Dir.pwd, Time.new.usec.to_s)
        Dir.mkdir dir
        dir
    else
        Dir.mktmpdir
    end
end

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
        
        opt.on("-v", "--verbose LEVEL", Integer, "How detailed is the logging. Range: [0,3]") { |v| $verbosity_level = v }
        opt.on("-o", "--output FILE", "Set non default output epub file location") { |o| options[:output] = validate_output_file(o) }
        opt.on("-m", "Make the epub flows from right-to-left like a manga") { |o| options[:manga] = o }
        opt.on("--mobi", "Convert the epub to mobi. Kindlegen must be in the program folder or PATH") { |o| options[:mobi] = o }
        opt.on("--toc", "Includes the table of contents at the end") { |o| options[:toc] = o }
        opt.on("--title NAME", "Set the epub title") { |o| options[:title] = o }
        opt.on("--debug", "Temp directories are not deleted and created in pwd") { |o| $local_temp_dir = o }
        opt.on("-h", "--help", "Prints this message") { |o| kill_if(opt.help) }
    end.parse!

    # handle positional args
    options[:filename] = fname = Pathname.new(ARGV.pop)
    kill_if("No cbz/rar/folder provided", fname == nil)
    kill_if("cbz/rar/folder does not exists", !File.exists?(fname) && !Dir.exists?(fname))
    options

rescue OptionParser::InvalidOption => e
    kill_if "\n#{e}. Use -h for help"
rescue OptionParser::InvalidArgument => ex
    kill_if "Invalid argument '#{ex.args[1]}' for the option '#{ex.args[0]}'. Make sure the argument type is correct"
rescue OptionParser::MissingArgument => exe
    kill_if "Missing argument for the option '#{exe.args[0]}'. Use -h for more help"
end

def to_mobi(epub)
    log('converting to mobi...', 1)
    log("\tnote: this can take a long time. (e.g., 320MB ~ 50 minutes)", 2)

    r, w = IO.pipe
    io = $verbosity_level < 3 ? w : $stdin
    pid = spawn('kindlegen', epub, [:in, :out, :err] => io)    
    Process.wait(pid)

    if $?.exitstatus == 0
        File.delete(epub)
    else
        puts('Something went wrong while converting to mobi with kindlegen')
    end
rescue Errno::ENOENT
    puts('kindlegen could not be found. Be sure it is on the path or in this program folder')
ensure
    r.close if r != nil
    w.close if w != nil
end

def main
    puts("Comic pub 0.1 - The poor man's comic to epub converter.\nBy Douglas S. Lacerda <hermespasser@gmail.com> under GPLv3\n")
    ops = parse_args

    epub_name = create_epub(ops)
    to_mobi(epub_name) if ops[:mobi]
end

main
