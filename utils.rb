$verbosity_level = 1
$log_stdout = $stdout
$local_temp_dir = false

def kill_if(text, condition=true)
    return if !condition
    puts(text)
    exit(1)
end

def temp_dir
    if $local_temp_dir 
        dir = File.join(Dir.pwd, Time.new.usec.to_s)
        Dir.mkdir dir
        dir
    else
        Dir.mktmpdir
    end
end

def log(text, level)
    $log_stdout << text if $verbosity_level >= level
end
