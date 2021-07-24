
# comic-pub

comic-pub is simple and easy to use program to convert batch of images to epub when [others](https://github.com/ciromattia/kcc) solutions fail

# Usage

``ruby main.rb <cbz|zip> [options]``

 - ``-v, --verbose LEVEL`` How detailed is the logging
 - ``-o, --output FILE`` Set non default output epub file name/location
 - ``-h, --help`` Prints this message
 - ``-m`` Make the epub flow from right-to-left like a manga
 - ``--title NAME`` Set the epub title. The default is the input name

# Requirements

* Ruby 3.0
* Necessary gems listed in [Gemfile](Gemfile)

# License

Licensed under GPLv3, see [LICENSE](LICENSE) file for details
