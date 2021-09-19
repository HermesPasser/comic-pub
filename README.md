
# comic-pub

comic-pub is simple and easy to use program to convert batch of images to epub when [others](https://github.com/ciromattia/kcc) solutions fail

NOTE 1: if you are not planning to convert it to mobi then is better to stick with cbz/r if you e-reader support it.  

Project status: [14/17 tasks done](https://github.com/HermesPasser/comic-pub/issues/1)

# Usage

## CLI

``ruby main.rb <folder|cbz|zip> [options]``

 - ``-v, --verbose LEVEL`` How detailed is the logging. Range: \[0,3\] (default 1)
 - ``-o, --output FILE`` Set non default output epub file name/location
 - ``-h, --help`` Print the contents of this section
 - ``-s, --split KIND`` How to handle double spread images
    * PRESERVE: rotate the image (default)
    * SPLIT: split the double spread in two and delete the original
    * BOTH: same as SPLIT but without deleting the original
 - ``-m`` Make the epub flow from right-to-left like a manga
 - ``--title NAME`` Set the epub title. The default is the input name
 - ``--mobi`` Convert to mobi and delete the .epub. Kindlegen must be in the program folder or PATH
 - ``--debug`` Temp directories are not deleted and created in pwd
 - ``--toc`` Adds a table of contents page at the end of the epub
 - ``--list-profiles`` List all the available profiles and their sizes  
 - ``-p, --profiles DEVICE`` Set the target device (will be used to resize larger images down to its size). --list-profiles will list all available profiles. (default no profile)  
 ## GUI
 
 To use the graphical user interface you have to launch the program without arguments (or double-click the main file if you OS is set to open .rb files with ruby). Note that you need to have tk bidings gem and the TkLib installed*  
 
``ruby main.rb``

*: tklib is not needed on windows since the bidings will came with the required files  

Most (but not all) features from the cli can work on the gui with the addition of batch conversion.   
![comic-pub's graphical user interface](https://i.imgur.com/Gcbc9uA.png)

# Requirements

* Ruby 3.0
* Necessary gems listed in [Gemfile](Gemfile)*
* ImageMagick or GraphicsMagick in the program folder or PATH  
* Kindlegen in the program folder or PATH (only needed if the option --mobi is given) 

*: tk is only necessary if you want to fire the graphical interface and you may need to instal tklib to get tk to work 

# License

Licensed under GPLv3, see [LICENSE](LICENSE) file for details
