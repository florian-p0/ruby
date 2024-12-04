require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "usage: searcher [OPTIONS] PATTERN [PATH ...]"
  
  opts.on("-A","--after-context <arg>", Integer, "prints the given number of following lines for each match") do |v|
    options[:after] = v
  end
  
  opts.on("-B","--before-context <arg>", Integer, "prints the given number of preceding lines for each match") do |v|
    options[:before] = v
  end
  
  opts.on("-c","--color","print with colors, highlighting the matched phrase in the output") do |v|
    options[:color] = v
  end
  
  opts.on("-C","--context <arg>", Integer, "prints the number of preceding and following lines for each match. this is equivalent to setting --before-context and --after-context") do |v|
    options[:context] = v
  end
  
  opts.on("-h","--hidden","search hidden files and folders") do |v|
    options[:hidden] = v
  end
  
  opts.on("--help","print this message") do |v|
    puts opts
    exit
  end
  
  opts.on("-i","--ignore-case","search case insensitive") do |v|
    options[:nocase] = v
  end
  
  opts.on("--no-heading","prints a single line including the filename for each match, instead of grouping matches by file") do |v|
    options[:nohead] = v
  end
  
end.parse!

pattern = Regexp.new(ARGV[0])
pattern2 = Regexp.new("^.*#{Regexp.escape(ARGV[0])}.*$")

path = ARGV[1]

files =  Dir.glob(path + '/**/*').select { |e| File.file? e }

for file in files do
  content = File.read(file)
  match = (content =~ pattern)
  match2 = content.scan(pattern2)
  if match != nil then
    puts file
    puts match2
  end
end