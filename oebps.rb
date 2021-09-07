require_relative './templates'
require_relative './image'
require 'securerandom'
require 'fileutils'
require 'nokogiri'
require 'tempfile'
require 'date'

MIMETYPES = {
    '.png' => 'image/png',
    '.jpg' => 'image/jpeg',
    '.jpeg' => 'image/jpeg',
    '.gif' => 'image/gif',
    '.xhtm' => 'application/xhtml+xml',
    '.xhtml' => 'application/xhtml+xml'
}

class OEBPSWriter
    def initialize(dest_oebps_dir, visible_toc=false, split_images = :preserve)
        @content = Nokogiri::XML($temp_content_opf_content)
        @toc = Nokogiri::XML.fragment($temp_toc_content) #::HTML is too much of a pain
        @dest_dir = dest_oebps_dir # since were going to create files we need to know where
        @visible_toc = visible_toc
        @landscape_mode = split_images
        
        @@left_spread = 'page-spread-left'
        @@right_spread = 'page-spread-right'
        @page_spread_direction = @left_spread
    end
    
    def set_cover(filename)
	ext = File.extname(filename)
	dest_folder = File.join(@dest_dir, comic_folder)
        dest_filename = File.join(dest_folder , 'cover' + ext)
	FileUtils.mkdir_p dest_folder if !Dir.exists? dest_folder
        FileUtils.cp(filename, dest_filename)

	node = insert_to_manifest(ext, 'cover', File.join(comic_folder , 'cover' + ext))
	node['properties'] = 'cover-image'
    end

    def comic_folder
        'comic'
    end

    def save        
        # TODO: maybe prevent anything from being add to @toc if is not visible
        self.insert_to_spine('toc', false) if @visible_toc
        @visible_toc = false
        
        # to_html replaces the Doctype with the html 4.0 version which is not valid in epub
        File.write(File.join(@dest_dir, 'content.opf'), @content.to_xml)
        File.write(File.join(@dest_dir, 'toc.xhtml'), @toc.to_xml)
    end

    def set_manga_mode(is_manga)
        # epub trickery
        mode = is_manga ? 'rtl' : 'ltr' 
        @content.search('spine').first['page-progression-direction'] = mode
        
        # mobi trickery
        mode = is_manga ? 'horizontal-rl' : 'horizontal-lr'
        @content.xpath('//*[@name="primary-writing-mode"]').first['content'] = mode

        @page_spread_direction = @@right_spread if is_manga
    end

    def set_metadata(args)
        get_by_id = Proc.new { |id| @content.xpath("//*[@id=\"#{id}\"]").first }
        
        get_by_id.call('cpub-title').inner_html = args[:title] if args[:title]

        get_by_id.call('uid').inner_html = "urn:uuid:#{SecureRandom.uuid}"
        get_by_id.call('cpub-modate').inner_html = DateTime.now.strftime("%Y-%m-%dT%H:%m:%SZ") # CCYY-MM-DDThh:mm:ssZ
    end

    def add_page(image_path, destination='', insert_to_toc, toc_name)
        img_folder_name = 'imgs'
        img_name = File.basename(image_path)
        relative_to_comic_img_dest = File.join(self.comic_folder, img_folder_name, destination) # comic/imgs/
        
        xhtml_name = File.basename(img_name, File.extname(image_path)) + '.xhtml' # /ch.xhtml
        if destination != '' 
            xhtml_name = File.join(destination, xhtml_name) # ch_name/ch.xhtml
            relative_img_path = File.join('..', img_folder_name, destination, img_name) # ../imgs/ch_dir
            
            abs_path = File.join(@dest_dir, self.comic_folder, destination)
            FileUtils.mkdir_p abs_path if !Dir.exists? abs_path
        else     
            relative_img_path = File.join(img_folder_name, img_name) # imgs/some-img
        end
        
        image_obj = Image.new(image_path)

        # If the w > h then either rotate or split
        # TODO: which side should a double page be?
        # TODO: with :both set, the two split image
        # will be on the wrong side. On the kindle seems
        # ok but i'm not sure if the change something
        # on a two screen e-reader 
        if !image_obj.landscape? || (@landscape_mode == :both || @landscape_mode == :preserve)
            # update the instance with the rotated/rescaled one
	    image_obj = self.add_img_file(image_path, relative_to_comic_img_dest)
            self.create_img_rendition(xhtml_name, relative_img_path, insert_to_toc, toc_name, image_obj)
        end

        split_image(image_obj, image_path, destination='', insert_to_toc)
    end

private
    def add_img_file(filename, destination)
        file_basename = File.basename(filename)
        absolute_dest = File.join(@dest_dir, destination)
        absolute_path = File.join(absolute_dest, file_basename)
        log "\tadding #{filename} to the oebps/#{destination}", 2
        FileUtils.mkdir_p absolute_dest if !Dir.exists? absolute_dest
        FileUtils.cp(filename, absolute_path)
        
        image_obj = Image.new(File.join(absolute_dest, file_basename)) # rotate the image on the EPUB, not the original image
        if image_obj.landscape?
            log "\t\trotating landscaped image", 3
            image_obj.rotate(-90)
            image_obj.save!
        end

        relative_path = File.join(destination, file_basename)
        self.insert_to_manifest(
                File.extname(filename), 
                relative_path.gsub('/', '-').gsub('\\', '-'), 
                relative_path)
	image_obj
    end

    def create_img_rendition(name, img_path, should_to_toc, toc_name, img_instance)
        html = Nokogiri::XML($empty_img_html) 
        html.search('title').first.inner_html = toc_name
        img_attr = html.search('img').first
        img_attr['src'] = img_path # img_path => imgs/some-img  
        img_attr['width'] = img_instance.width
        img_attr['height'] = img_instance.height
         
        # create the file
        file_obj = open(File.join(@dest_dir, self.comic_folder, name), 'a+')
        file_obj << html.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION) # will preserve the original xml and doctype order
        
        relative_path = File.join(self.comic_folder, name)
        id = relative_path.gsub('/', '-').gsub('\\', '-')
        
        self.insert_to_manifest(File.extname(name), id, relative_path)
        self.insert_to_spine(id, true)
        self.insert_to_toc(relative_path, toc_name) if should_to_toc
    ensure
        file_obj.close if file_obj != nil
    end
    
    def split_image(img, image_path, destination, insert_to_toc)
        return if !img.landscape? || @landscape_mode == :preserve
        
        log "\t\tsplitting landscaped image", 3
        pathname = Pathname.new(image_path)
        stem = pathname.basename.sub_ext('').to_s
        ext = pathname.extname.to_s
        
        # these files will have very long and ugly names
        l_filename = Tempfile.new([ "#{stem}-l", ext ]).path.to_s
        l = img.copy(l_filename)
        l.crop_left
        l.save!

        r_filename = Tempfile.new([ "#{stem}-r", ext ]).path.to_s
        r = img.copy(r_filename)
        r.crop_right
        r.save!
        
        add_page(l_filename, destination, insert_to_toc, "#{stem}-left")
        add_page(r_filename, destination, insert_to_toc, "#{stem}-right")
    end

    def change_direction
        @page_spread_direction = @page_spread_direction == @@left_spread ? @@right_spread : @@left_spread
    end

    def insert_to_manifest(extension, id, href)
        item_node = Nokogiri::XML::Node.new('item', @content)
        item_node['id'] = id
        item_node['href'] = href
        item_node['media-type'] = MIMETYPES[extension.downcase]
        @content.search('manifest').first.add_child(item_node)
        item_node
    end

    def insert_to_spine(id, set_spread_direction)
        item_node = Nokogiri::XML::Node.new('itemref', @content)
        item_node['idref'] = id
        item_node['linear'] = 'yes'
        
        # TODO: we will need to handle this in a more intelligent way
        # when we start adding more pages (eg. an option when the big
        # page is split in two, but the original big page is stil 
        # in the doc, we need to make sure that the two spliten 
        # pages match and maybe that the big page is the fist)
        if set_spread_direction
            # FIXME: setting this will break the convertion to 
            # mobi if the  so let's worry about this later, error:
            # Please specify the Original-resolution metadata value in the format WIDTH x HEIGHT
            # Add a meta like this to fix: 
            #  <meta name="original-resolution" content="WIDTHxHEIGHT" />
            
            # define if this is the left or right from a two-pages spread
            # item_node['properties'] = @page_spread_direction 
            # self.change_direction 
        end
        @content.search('spine').first.add_child(item_node)
        item_node
    end

    def insert_to_toc(relative_filename, content_name) 
        # <li><a href="comic/chapter_1.xhtml">Chapter 1</a></li>
        list_node = Nokogiri::XML::Node.new('li', @toc)
        anchor_node = Nokogiri::XML::Node.new('a', @toc)
        anchor_node['href'] = relative_filename
        anchor_node.inner_html = content_name
        list_node.add_child(anchor_node)
        @toc.search('.contents').first.add_child(list_node)
        anchor_node
    end
end
