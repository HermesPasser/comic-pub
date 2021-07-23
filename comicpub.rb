require_relative './ziputils'
require_relative './templates'
require_relative './oebps'
require 'fileutils'
require 'pathname'
require 'tmpdir'

def create_mimetype(root_epub_dir)
    open(File.join(root_epub_dir, 'mimetype'), 'a+') do |f|
        f.write('application/epub+zip')
    end
end

def create_meta_inf_folder(root_epub_dir)
    metainf_dir = File.join(root_epub_dir, 'META-INF')
    Dir.mkdir metainf_dir

    open(File.join(metainf_dir, 'container.xml'), 'a+') do |f|
        f.write($container_content)
    end
end

def create_oebps_folder(root_epub_dir)
    oebps_dir = File.join(root_epub_dir, 'OEBPS')
    Dir.mkdir oebps_dir
    Dir.mkdir File.join(oebps_dir, 'css')
    open(File.join(oebps_dir, 'css', 'main.css'), 'a+') { |f| }
end

def create_structure()
    # --ZIP Container--
    # mimetype
    # META-INF/
    #   container.xml
    # OEBPS/
    #   css/main.css
    #   comic/chapter_1/  images here
    #   comic/chapter_1.xhtml
    #   content.opf
    #   toc.xhtml
    root_epub_dir = Dir.mktmpdir
    log("created temp dir #{root_epub_dir}", 3)

    create_mimetype(root_epub_dir)
    create_meta_inf_folder(root_epub_dir)
    create_oebps_folder(root_epub_dir)
   
    return root_epub_dir;
end

def unzip_cbz(zip_filename)
    temp_dir = Dir.mktmpdir
    # TODO: imgs may be inside of a root folder in the zip, deal with it
    Zipper.unzip(zip_filename, temp_dir)
    temp_dir
end

def process_cbz_imgs(img_folder, writer)
    # TODO: deal with subfolders, for now we were putting all the imgs in img/
    # but later each subfolder should be copied to /img/sub/ and the first img
    # from each subfolder should be the start of a chapter
    # There is the case that instead the imgs are zipped inside of a folder
    i = 1
    log  "adding images to epub...", 1
    Dir.entries(img_folder).each do |file|
        extension = File.extname(file)
        
        next if File.directory? file
        unless ['.png', '.jpg', '.jpeg', '.gif'].include? extension
            log "\tignoring non image file #{file}", 2
            next
        end
        
        add_to_toc = i == 1 ? true : false
        full_path = File.join(img_folder, file)
        writer.add_page(full_path, '', add_to_toc, 'Chapter Name')
        i += 1
    end
    writer
end

def create_epub(args)
    # TODO: drop all strings to use Pathnames only
    if args[:output]
        file_no_ext = File.basename(args[:output].sub_ext('').to_s)
        epub_filename = args[:output].to_s
    else
        path_no_ext = Pathname.new(args[:filename]).sub_ext('').to_s 
        file_no_ext = File.basename(path_no_ext)
        epub_filename = path_no_ext + '.epub'
    end

    epub_temp_folder = create_structure
    
    # unzip cbz and read the xmls here
    # TODO: check if is not a folder before

    zip_temp_dir = unzip_cbz(args[:filename])

    writer = OEBPSWiter.new(File.join(epub_temp_folder, 'OEBPS'))
    writer.set_manga_mode(args[:manga] || false)
    process_cbz_imgs(zip_temp_dir, writer)
    writer.set_metadata(:title => args[:title] || file_no_ext)
    writer.save
    
    # TODO: save xhml from writer
    log("creating #{epub_filename}...", 1)
    zip = Zipper.new epub_filename
    zip.store   File.join(epub_temp_folder, 'mimetype'), 'mimetype'
    zip.add_dir File.join(epub_temp_folder, 'META-INF'), 'META-INF'
    zip.add_dir File.join(epub_temp_folder, 'OEBPS'), 'OEBPS'
    zip.close
    rescue => exception
        raise exception
    ensure  
        FileUtils.rm_r epub_temp_folder if epub_temp_folder != nil
        FileUtils.rm_r zip_temp_dir if zip_temp_dir != nil
        epub_filename
end
