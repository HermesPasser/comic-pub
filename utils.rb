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
    $log_stdout << text + "\n" if $verbosity_level >= level
end

def to_mobi(epub)
    log('converting to mobi...', 1)
    log("\tnote: this can take a long time. (e.g., 320MB ~ 50 minutes)", 2)

    r, w = IO.pipe
    io = $verbosity_level < 3 ? w : $stdin
    pid = spawn('kindlegen', epub, [:in, :out, :err] => io)    
    Process.wait(pid)

    status = $?.exitstatus
    if status == 0 || status == 1
        File.delete(epub)
    else
        puts('Something went wrong while converting to mobi with kindlegen')
    end
rescue Errno::ENOENT
    puts('kindlegen could not be found. Be sure it is on the path or in this program folder')
ensure
    r.close if r != nil
    w.close if w != nil
end
