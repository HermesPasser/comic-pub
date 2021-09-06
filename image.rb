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

    def crop(x, y, w, h)
        @img_obj.crop("#{w}x#{h}+#{x}+#{y}") # WxH+X+Y
    end

    def crop_left
        # Removes the right side of the image

        w = width / 2
        h = height - 1
        crop(0, 0, w, h)
    end

    def crop_right
        # Removes the left side of the image

        w = width / 2
        h = height - 1
        crop(w, 0, w, h)
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

    def resize(w, h)
        @img_obj.resize("#{w}x#{h}")
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
