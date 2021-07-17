require 'rubygems'
require 'zip'

class Zipper
    def initialize(output)
        @zip_obj = Zip::OutputStream.new(output)
        @files = []
    end

    def store(input_filepath, output_filepath)
        @zip_obj.put_next_entry(output_filepath, nil, nil, Zip::Entry::STORED, Zlib::NO_COMPRESSION)
        @zip_obj.write IO.read(input_filepath)
    end

    def add_dir(dirpath, output_filepath)
        Dir["#{dirpath}/**/**"].each do |file|
            # relative to the 'root' epub zip folder, eg.
            # c:\tempfile\foo\file.txt => foo\file.txt
            filepath_relative = File.join(output_filepath, File.basename(file))

            puts "\tsaving #{file} as #{filepath_relative}"
            @files.append([file, filepath_relative])
        end
    end

    def close
        @files.each do |file_location, filename|           
            @zip_obj.put_next_entry(filename, nil, nil, Zip::Entry::DEFLATED, Zlib::BEST_COMPRESSION)
            @zip_obj.write IO.read(file_location)
        end
        @zip_obj.close
    end
end
