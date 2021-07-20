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
            next if File.directory? file

            # relative to the 'root' zip folder, eg.
            # c:\tempfile\foldertozip\foo\file.txt => foo\file.txt
            filepath_relative = file[file.index(output_filepath), file.length]
           
            puts "\tsaving #{file} as #{filepath_relative}"
            @files.append([file, filepath_relative])
        end
    end

    def close
        @files.each do |file_location, filename|           
            @zip_obj.put_next_entry(filename, nil, nil, Zip::Entry::DEFLATED, Zlib::BEST_COMPRESSION)
            @zip_obj.write IO.binread(file_location)
        end
        @zip_obj.close
    end

    def self.unzip(zip_filepath, destination)
        puts "unzipping #{zip_filepath}"
        Zip::File.open(zip_filepath) do |zip_file|
            zip_file.each do |f|
                fpath = File.join(destination, f.name)
                puts "\t#{f} => #{fpath}"
                zip_file.extract(f, fpath)
            end
        end
    end
end
