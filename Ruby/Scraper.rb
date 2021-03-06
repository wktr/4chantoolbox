#!/usr/bin/ruby

## Libraries
require"getoptlong"
require"open-uri"

## Defaults
@verbose = true
@output = "./"
@refresh = 10

## Globals
$downtot = 0

##Functions
def v_print instr
    puts instr if @verbose
end

def usage
    v_print "=================================================="
    v_print "Usage: Scraper-Ruby [OPTION] <thread url>"
    v_print "Default OPTIONS: --output ./ --thread 10"
    v_print "Bash script to scrape 4chan, part of 4chantoolbox."
    v_print ""
    v_print " -o/--output set output dir"
    v_print " -q/--quiet go silent"
    v_print " -t/--timer N thread refresh timer"
    v_print " -h/--help this message"
    v_print ""
    v_print "insert <witty comment> here"
    v_print "=================================================="
    exit
end

## Handle URL arg
if ARGV.length == 0 then
    usage
else
    @url = ARGV.pop
end

## Handle flags
opts = GetoptLong.new(
    [ '-q', GetoptLong::NO_ARGUMENT ],
    [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
    [ '--output', '-o', GetoptLong::OPTIONAL_ARGUMENT ],
    [ '--timer', '-t', GetoptLong::OPTIONAL_ARGUMENT ]
)

opts.each do |opt, arg|
    if opt == '-q' then
        @verbose = False
    elsif ['-h', '--help'].include? opt then
        usage()
    elsif ['-o', '--output'].include? opt then
        @output = arg
    elsif ['-t', '--timer'].include? opt then
        @refresh = arg.to_i
    end
end

##Error check the given path
if not File.directory?(@output) then
    puts "Given output location '#{@output}' is not a directory. EXITING!"
    exit(0)
end

##Report which options we're using
v_print("Downloading #{@url}")
v_print("Saving to location #{@output}")
v_print("Timer set to every #{@refresh.to_s} seconds.")

## Main loop
downtot = 0 # Has to be initialized (even if with the value of zero)

loop do
    begin
        lasttime = Time.now()

        # Grab the page and split out the image URLS
        html = open(@url);
        v_print("Page " + @url + " downloaded. Processing images.")
        
        # Grab all image links/paths/...
        images = html.read.scan(/http:\/\/images\.4chan\.org\/\w+\/src\/\d+\.(?:png|gif|jpg)/)
        
        images.to_a.each do |image|
            # Split the image name from the URL and get a full path to write to
            image =~ /src\/(.*$)/
            imagename = $1
            fullpath = @output + imagename

            # Get the file if necessary
            if File.exists?(fullpath) then
                v_print("File \'#{fullpath}' exists. Skipping.")
            else
                v_print("Getting #{image}")
                File.open(fullpath, 'wb') do |localFile|
                    localFile << open(image).read()
                end
                downtot += 1
            end
        end

        # Timer
        looptime = (Time.now() - lasttime).to_i;
        lasttime = Time.now();
        v_print("Finished in #{looptime} seconds.")
        if looptime < @refresh then
            v_print("Sleeping for #{@refresh - looptime} seconds.")
            sleep(@refresh - looptime)
        end

    # Handle the keyboard interrupt event
    rescue Interrupt, SystemExit
        puts "\nInterupted. #{downtot} pics downloaded in total from #{@url}."
        exit(0)
    end
end
