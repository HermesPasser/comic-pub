$container_content = <<END
<?xml version="1.0"?>
    <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
    <rootfiles>
        <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
    </rootfiles>
</container>
END

$temp_content_opf_content = <<END
<?xml version="1.0" encoding="UTF-8" ?>
<package version="3.0" unique-identifier="uid" xmlns="http://www.idpf.org/2007/opf">
 	<metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">
		<dc:title>add</dc:title>
		<dc:language>en-US</dc:language>
		<dc:contributor id="contributor">add</dc:contributor>
		<dc:creator>add author</dc:creator>
		<dc:identifier id="uid">add</dc:identifier>

		<meta property="dcterms:modified">2021-07-12T18:18:29Z</meta>
		<meta name="fixed-layout" content="true" />
		<meta name="book-type" content="comic" />
		<meta name="primary-writing-mode" content="horizontal-rl" />
		<meta name="zero-gutter" content="true" />
		<meta name="zero-margin" content="true" />
		<meta name="ke-border-color" content="#FFFFFF" />
		<meta name="ke-border-width" content="0" />
		<meta name="orientation-lock" content="portrait" />
		<meta name="region-mag" content="true" />
	</metadata>

	<manifest>
	    <item id="toc" 			href="toc.xhtml" media-type="application/xhtml+xml" properties="nav" />
	    <item id="chapter_1" 	href="comic/chapter_1.xhtml" media-type="application/xhtml+xml" />
	    <item id="main_css" 	href="css/main.css" media-type="text/css" />
	</manifest>

	<spine>
		<itemref idref="toc" />
	    <itemref idref="chapter_1" />
	</spine>
</package>
END
# about <dc:identifier>
# 	must have the same id in the meta inside toc.ncx
#	https://www.mobileread.com/forums/showthread.php?t=314516
#	uid example: <dc:identifier id="uid">urn:uuid:89a41639-0722-4bd4-90da-5b628a510d30</dc:identifier>

# NOTES:
# cover should be add in the spine before the other stuff, maybe?
# to add a toc 
#	sprine <itemref idref="comic/toc" />
#	mainfest <item id="toc" href="toc.xhtml" media-type="application/xhtml+xml" properties="nav" />
# on the spine maybe this linerar and page-spread are important to render the pages correctly (it was in a kcc generated epub)
# <itemref idref="chapter1" linear="yes" properties="page-spread-right" />
# <itemref idref="chapter2" linear="yes" properties="page-spread-left" />

# Items to add late:
# <meta name="cover" content="cover" />
# <meta name="original-resolution" content="1072x1448" /> this one is from KCC, may be useful

$temp_toc_content = <<END
<?xml version="1.0" encoding="utf-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
    <head>
        <title>toc.xhtml</title>
        <link href="css/main.css" rel="stylesheet" type="text/css" />
    </head>
    <body>
        <nav id="toc" epub:type="toc">
            <h1 class="frontmatter">Table of Contents</h1>
            <ol class="contents">
                <li><a href="comic/chapter_1.xhtml">Chapter 1</a></li>
            </ol>
        </nav>
    </body>
</html>
END

# <!-- if we ever need to use css in this... -->
# <!-- <link href="template.css" rel="stylesheet" type="text/css" /> -->

$place_holder_main_content = <<END
<?xml version="1.0" encoding="utf-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
    <head>
        <title>1_hello.xhtml</title>
    </head>
    <body>
        <h1>Hello World!</h1>
    </body>
</html> 
END
# to ref a css in the file <link> like any ordinary html code