require_relative './ziputils'
require_relative './strings'
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
    Dir.mkdir File.join(oebps_dir, 'comic')
    Dir.mkdir File.join(oebps_dir, 'css')

    open(File.join(oebps_dir, 'content.opf'), 'a+') do |f|
        f.write($temp_content_opf_content)
    end

    # open(File.join(oebps_dir, 'toc.ncx'), 'a+') do |f|
    #     f.write($temp_toc_contenxt)
    # end
    
    open(File.join(oebps_dir, 'toc.xhtml'), 'a+') do |f|
        f.write($temp_toc_content)
    end
    
    # placeholder content
    open(File.join(oebps_dir, 'comic', 'chapter_1.xhtml'), 'a+') do |f|
        f.write($place_holder_main_content)
    end

    open(File.join(oebps_dir, 'css', 'main.css'), 'a+') { |f| }

    # since is not mandatory, let's think this out later
    # open(File.join(oebps_dir, 'nav.ncx'), 'a+') do |f|
        # nothing for now
    # end
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
    root_epub_dir = temp_dir = Dir.mktmpdir
    puts("created temp dir #{root_epub_dir}")

    create_mimetype(root_epub_dir)
    create_meta_inf_folder(root_epub_dir)
    create_oebps_folder(root_epub_dir)
   
    return root_epub_dir;
end

def create_epub(epub_name)
    epub_filename = Pathname.new(epub_name).sub_ext('').to_s + '.epub'
    folder = create_structure
    
    puts("creating #{epub_filename}...")
    zip = Zipper.new epub_filename
    zip.store   File.join(folder, 'mimetype'), 'mimetype'
    zip.add_dir File.join(folder, 'META-INF'), 'META-INF'
    zip.add_dir File.join(folder, 'OEBPS'), 'OEBPS'
    zip.close
    # loop  {}
    FileUtils.rm_r folder
end
