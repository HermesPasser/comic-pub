
$PROFILES = {
    'kindle1-10'            => [600, 800],
    'kindle-touch'          => [600, 800],
    'kindle-dx'             => [824, 1200], 
    'kindle-paperwhite1-2'  => [768, 1024], # 1st, 2nd gen
    'kindle-paperwhite3-4'  => [1072, 1448], # 3rd, 4th gen
    'kindle-voyage'         => [1072, 1448], 
    'kindle-oasis1'         => [1072, 1448], 
    'kindle-oasis2-3'       => [1680, 1264],

    'kobo-nia'              => [1024, 758],
    'kobo-libra-h2o'        => [1264, 1680], 
    'kobo-elipsa'           => [1404, 1872],
    'kobo-libra'            => [1680, 1264]
}

def list_profiles
    printf "%-25s %s\n", 'device', 'screen size (px)'
    puts '-' * 25
    $PROFILES.each do |model , size|
        printf "%-25s %sx%s\n", model, size[0], size[1]
    end
end
