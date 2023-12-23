require_relative './ziputils'
require_relative './templates'
require_relative './oebps'
require 'fileutils'
require 'pathname'

$cover_added = false

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
    root_epub_dir = temp_dir
    log("created temp dir #{root_epub_dir}", 3)

    create_mimetype(root_epub_dir)
    create_meta_inf_folder(root_epub_dir)
    create_oebps_folder(root_epub_dir)
   
    return root_epub_dir;
end

def unzip_cbz(zip_filename)
    tempdir = temp_dir
    # TODO: imgs may be inside of a root folder in the zip, deal with it
    Zipper.unzip(zip_filename, tempdir)
    tempdir
end

def process_cbz_imgs(img_folder, writer, chapter_name = '', folder_name = '')
    img_folder = Pathname.new(img_folder)
    # TODO: make each chapter be in its own folder in the epub instead of
    # the comic/img/, maybe comic/img/chapter/ or comic/chapter
    
    # FIXME: beware that 800MB is the mobi's image size limit

    i = 1
    found_chapters = false
    Pathname.new(img_folder).children.each do |entry|
		fullpath = entry.expand_path
        extension = entry.extname.downcase

        # TODO: maybe prevent from going doing within the filesystem after the first level of recursion?

		if entry.directory?
			found_chapters = true
            log "\tfolder '#{entry}' detected, considering it a chapter if any image is inside", 2
            
            folder_name = entry.basename.to_s
            process_cbz_imgs(fullpath.to_s, writer, folder_name, folder_name)
            log '', 2
            next
        end

        unless ['.png', '.jpg', '.jpeg', '.gif'].include? extension
            log "\tignoring non image file #{entry}", 2
            next
        end
        
        # This assumes that #entries will order the folders first
        # maybe anylize the img_folder before loop tru everything
        if found_chapters
            log "\tlocated images that are not part of any chapter", 2
            chapter_name = 'left over pages'
        end

        add_to_toc = i == 1
		
	    if !$cover_added
            writer.set_cover(fullpath)
	        $cover_added = true
	    end

        if chapter_name == '' # the image name as title if none was given
            chapter_name = entry.basename('.*').to_s
        end

        writer.add_page(fullpath, folder_name, add_to_toc, chapter_name)
        i += 1
    end
    writer
end

def create_epub(args)
    # TODO: drop all strings to use Pathnames only
    input_filename = args[:filename]
    if args[:output]
        file_no_ext = File.basename(input_filename.sub_ext('').to_s)
        epub_filename = args[:output].to_s
    else
        path_no_ext = args[:filename].sub_ext('').to_s 
        file_no_ext = File.basename(path_no_ext)
        epub_filename = path_no_ext + '.epub'
    end

    epub_temp_folder = create_structure
    zip_temp_dir = input_filename.directory? ? input_filename.to_s : unzip_cbz(input_filename)

    log  "adding images to epub...", 1
    writer = OEBPSWriter.new(File.join(epub_temp_folder, 'OEBPS'), args[:toc] || false, args[:split] || :preserve)
    writer.profile = args[:profile] if args[:profile]
    writer.set_manga_mode(args[:manga] || false)
    process_cbz_imgs(zip_temp_dir, writer)
    writer.set_metadata(:title => args[:title] || file_no_ext)
    writer.save
    
    log("creating #{epub_filename}...", 1)
    zip = Zipper.new epub_filename
    zip.store   File.join(epub_temp_folder, 'mimetype'), 'mimetype'
    zip.add_dir File.join(epub_temp_folder, 'META-INF'), 'META-INF'
    zip.add_dir File.join(epub_temp_folder, 'OEBPS'), 'OEBPS'
    zip.close
    epub_filename
rescue => exception
    raise exception
ensure
    if !$local_temp_dir
        FileUtils.rm_r epub_temp_folder if epub_temp_folder != nil
        FileUtils.rm_r zip_temp_dir if !input_filename.directory? && zip_temp_dir != nil
    end
end
