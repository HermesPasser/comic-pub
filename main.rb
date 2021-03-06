require_relative './comicpub'
require_relative './profiles'
require_relative './utils'
require 'optparse'

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
        opt.on("-s", "--split KIND", "How to handle double spread images. PRESERVE: rotate the image; SPLIT: split the image in two; BOTH: split the image in two but leave a copy rotated copy of the original image") do |o| 
		    opts = { 'preserve' => :preserve, 'split' => :split, 'both' => :both }
            options[:split] = opts[o.downcase]
	    end
        opt.on("--list-profiles", "List all the available profiles and their sizes") { |o| list_profiles && exit }
        opt.on("-p", "--profile DEVICE", "Set the target device (will be used to resize larger images down to its size). --list-profiles will list all available profiles. (default no profile)") do |o| 
            profile = $PROFILES[o.downcase]
            kill_if("No profile '#{o}'. To list all profiles use --list-profiles command", profile == nil)
		    options[:profile] = profile
	    end
        opt.on("-h", "--help", "Prints this message") { |o| kill_if(opt.help) }
    end.parse!

    # handle positional args
    msg = 'No cbz/rar/folder provided'
    kill_if(msg, ARGV == [])
    options[:filename] = fname = Pathname.new(ARGV.pop)
    kill_if(msg, fname == nil)
    kill_if('cbz/rar/folder does not exists', !File.exists?(fname) && !Dir.exists?(fname))
    options

rescue OptionParser::InvalidOption => e
    kill_if "\n#{e}. Use -h for help"
rescue OptionParser::InvalidArgument => ex
    kill_if "Invalid argument '#{ex.args[1]}' for the option '#{ex.args[0]}'. Make sure the argument type is correct"
rescue OptionParser::MissingArgument => exe
    kill_if "Missing argument for the option '#{exe.args[0]}'. Use -h for more help"
end

def main
    puts("Comic pub 0.1 - The poor man's comic to epub converter.\nBy Douglas S. Lacerda <hermespasser@gmail.com> under GPLv3\n")
    ops = parse_args

    epub_name = create_epub(ops)
    to_mobi(epub_name) if ops[:mobi]
end

def try_import_ui 
    found = true
    require 'tk'
rescue LoadError
    found = false
ensure
    found
end

if __FILE__ == $0
    if ARGV == [] && try_import_ui # if no arg is given and tk is installed then open the UI
        load 'ui/main_win.rb'
        exit
    end
    main
end
