require_relative './strings'
require 'securerandom'
require 'fileutils'
require 'nokogiri'
require 'date'

MIMETYPES = {
    '.png' => 'image/png',
    '.jpg' => 'image/jpeg',
    '.jpeg' => 'image/jpeg',
    '.gif' => 'image/gif',
    '.xhtm' => 'application/xhtml+xml',
    '.xhtml' => 'application/xhtml+xml'
}

class OEBPSWiter
    def initialize(dest_oebps_dir, visible_toc=false)
        @content = Nokogiri::XML($temp_content_opf_content)
        @toc = Nokogiri::XML.fragment($temp_toc_content) #::HTML is too much of a pain
        @dest_dir = dest_oebps_dir # since were going to create files we need to know where
       
        # TODO: maybe prevent anything from being add to @toc if is not visible
        self.insert_to_spine('toc') if visible_toc
    end

    
    def comic_folder
        'comic'
    end

    def save
        # Dir.mkdir @dest_dir
        # to_html replaces the Doctype with the html 4.0 version which is not valid in epub
        File.write(File.join(@dest_dir, 'content.opf'), @content.to_xml)
        File.write(File.join(@dest_dir, 'toc.xhtml'), @toc.to_xml)
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
        xhtml_name = File.basename(img_name, File.extname(image_path)) + '.xhtml'
        relative_to_comic_img_dest = File.join(self.comic_folder, img_folder_name, destination) # # comic/imgs/
        relative_img_path = File.join(img_folder_name, img_name) # imgs/some-img
        
        self.add_img_file(image_path, relative_to_comic_img_dest)
        self.create_img_rendition(xhtml_name, relative_img_path, insert_to_toc, toc_name)
    end

private
    def add_img_file(filename, destination)
        file_basename = File.basename(filename)
        absolute_dest = File.join(@dest_dir, destination)
        
        puts "\tadding #{filename} to the oebps/#{destination}"
        FileUtils.mkdir_p absolute_dest if !Dir.exists? absolute_dest
        FileUtils.cp(filename, File.join(absolute_dest, file_basename))

        relative_path = File.join(destination, file_basename)
        self.insert_to_manifest(
                File.extname(filename), 
                relative_path.gsub('/', '-').gsub('\\', '-'), 
                relative_path) 
    end

    def create_img_rendition(name, img_path, should_to_toc, toc_name)
        file_basename = File.basename(name)       
        
        html = Nokogiri::XML($empty_img_html) 
        html.search('title').first.inner_html = toc_name
        html.search('img').first['src'] = img_path # img_path => imgs/some-img  
        
        # create the file
        file_obj = open(File.join(@dest_dir, self.comic_folder, name), 'a+')
        file_obj << html.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION) # will preserve the original xml and doctype order
        
        relative_path = File.join(self.comic_folder, file_basename)
        id = relative_path.gsub('/', '-').gsub('\\', '-')
        
        self.insert_to_manifest(File.extname(name), id, relative_path)
        self.insert_to_spine(id)
        self.insert_to_toc(relative_path, toc_name) if should_to_toc
        ensure
            file_obj.close if file_obj != nil
    end

    def insert_to_manifest(extension, id, href)
        item_node = Nokogiri::XML::Node.new('item', @content)
        item_node['id'] = id
        item_node['href'] = href
        item_node['media-type'] = MIMETYPES[extension.downcase]
        @content.search('manifest').first.add_child(item_node)
        item_node
    end

    def insert_to_spine(id)
        item_node = Nokogiri::XML::Node.new('itemref', @content)
        item_node['idref'] = id
        item_node['linear'] = 'yes' #or no
        # item_node['properties'] = page-spread-right or page-spread-left
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