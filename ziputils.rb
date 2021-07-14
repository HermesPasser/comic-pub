require 'rubygems'
require 'zip'
# já que vou ter que add coisas isoladamentes la no comicpub.rb
class Zipper
    def initialize(output)
        @filename = output
        @rubyzip_object = Zip::File.open(output, Zip::File::CREATE)
        @rubyzip_object.close
    end

    def add_no_compreension(input_filepath, output_filepath)
        Zip.default_compression = 0
        Zip::File.open(@filename) do |zipfile|
            zipfile.add(output_filepath, input_filepath)
        end
    end

    def add_dir(dirpath, output_filepath)
        # Zip.default_compression = 7
        Zip::File.open(@filename) do |zipfile|
            Dir["#{dirpath}/**/**"].each do |file|
                # relative to the 'root' epub zip folder, eg.
                # c:\tempfile\foo\file.txt => foo\file.txt

                filepath_relative = File.join(output_filepath, File.basename(file))
                p file, filepath_relative
                zipfile.add(filepath_relative, file)
            end
        end
    end
end
