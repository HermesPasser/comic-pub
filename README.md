
# comic-pub

comic-pub is simple and easy to use program to convert batch of images to epub when [others](https://github.com/ciromattia/kcc) solutions fail

NOTE 1: if you are not planning to convert it to mobi then is better to stick with cbz/r if you e-reader support it.  

Project status: [11/17 tasks done](https://github.com/HermesPasser/comic-pub/issues/1)

# Usage

``ruby main.rb <folder|cbz|zip> [options]``

 - ``-v, --verbose LEVEL`` How detailed is the logging. Range: \[0,3\]
 - ``-o, --output FILE`` Set non default output epub file name/location
 - ``-h, --help`` Prints the contents of this section
 - ``-m`` Make the epub flow from right-to-left like a manga
 - ``--title NAME`` Set the epub title. The default is the input name
 - ``--mobi`` Convert to mobi and delete the .epub. Kindlegen must be in the program folder or PATH
 - ``--debug`` Temp directories are not deleted and created in pwd
 - ``--toc`` Adds a table of contents page at the end of the epub

# Requirements

* Ruby 3.0
* Necessary gems listed in [Gemfile](Gemfile)
* ImageMagick or GraphicsMagick in the program folder or PATH  
* Kindlegen in the program folder or PATH (only needed if the option --mobi is given) 

# License

Licensed under GPLv3, see [LICENSE](LICENSE) file for details
