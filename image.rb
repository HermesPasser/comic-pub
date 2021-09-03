require 'mini_magick'

class Image
    def initialize(src)
        @src = src
        @img_obj = MiniMagick::Image.new(src)
    end

    def copy(filename)
        save(filename)
        Image.new(filename)
    end

    def landscape?
        @img_obj.landscape?
    end

    def width
        @img_obj.dimensions[0]
    end

    def height
        @img_obj.dimensions[1]
    end

    def resize(percent)
        @img_obj.resize("#{percent}%")
    end

    def rotate(degrees)
        @img_obj.rotate(degrees.to_s)
    end

    def save(filename)
        @img_obj.write(filename)
    end

    def save!
        @img_obj.write(@src)
    end
end
