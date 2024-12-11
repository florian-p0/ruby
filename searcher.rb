require 'optparse'

# Optionen initialisieren
options = {}

# Kommandozeilenargumente definieren
OptionParser.new do |opts|
  opts.banner = "usage: searcher [OPTIONS] PATTERN [PATH ...]"
  
  opts.on("-A", "--after-context <arg>", Integer, "prints the given number of following lines for each match") do |v|
    options[:after] = v
  end
  
  opts.on("-B", "--before-context <arg>", Integer, "prints the given number of preceding lines for each match") do |v|
    options[:before] = v
  end
  
  opts.on("-c", "--color", "print with colors, highlighting the matched phrase in the output") do |v|
    options[:color] = v
  end
  
  opts.on("-C", "--context <arg>", Integer, "prints the number of preceding and following lines for each match. this is equivalent to setting --before-context and --after-context") do |v|
    options[:context] = v
    options[:before] = v
    options[:after] = v
  end
  
  opts.on("-h", "--hidden", "search hidden files and folders") do |v|
    options[:hidden] = v
  end
  
  opts.on("-i", "--ignore-case", "search case insensitive") do |v|
    options[:nocase] = v
  end
  
  opts.on("--no-heading", "prints a single line including the filename for each match, instead of grouping matches by file") do |v|
    options[:nohead] = true
  end
  
  opts.on("--help", "print this message") do
    puts opts
    exit
  end
end.parse!

# Das pattern aus den Argumenten abrufen
pattern = ARGV.shift

# Standardpfad ist das aktuelle Verzeichnis, wenn kein Pfad angegeben wurden
paths = ARGV.empty? ? ["."] : ARGV

# Fehler ausgeben, wenn kein pattern angegeben ist
if pattern.nil? || pattern.empty?
  puts "Error: PATTERN is required."
  exit 1
end

# Optionen für den regulären Ausdruck festlegen (Groß-/Kleinschreibung ignorieren)
regexp_options = options[:nocase] ? Regexp::IGNORECASE : nil
regexp = Regexp.new(pattern, regexp_options)

# Alle angegebenen Pfade durchsuchen
paths.each do |path|
  Dir.glob("#{path}/**/*", File::FNM_DOTMATCH).each do |file|
  next if File.directory?(file) # Verzeichnisse überspringen
  next if !options[:hidden] && File.basename(file).start_with?(".") # Versteckte Dateien ignorieren, falls nicht erlaubt
  
  begin
    # Datei lesen und ungültige Zeichen durch `?` ersetzen
    lines = File.open(file, "r:bom|utf-8").readlines.map(&:chomp)
  rescue ArgumentError => e
    STDERR.puts "Skipping file #{file} due to encoding issues: #{e.message}"
    next
  rescue StandardError => e
    STDERR.puts "Error reading file #{file}: #{e.message}"
    next
  end
  
  matches = []
  lines.each_with_index do |line, idx|
    # Überprüfen, ob die Zeile das pattern enthält
    if line.force_encoding("UTF-8").scrub.match?(regexp)
      # Kontextgrenzen berechnen
      start_idx = [0, idx - options.fetch(:before, 0)].max
      end_idx = [lines.size - 1, idx + options.fetch(:after, 0)].min
      matches << { start_idx: start_idx, end_idx: end_idx, match_line: idx }
    end
  end
  
  # Überlappende oder benachbarte Matches verschmelzen
  merged_matches = []
  matches.sort_by { |m| m[:start_idx] }.each do |current|
    if merged_matches.empty? || current[:start_idx] > merged_matches.last[:end_idx]
      # Kein Überlappen: Neues Match hinzufügen
      merged_matches << current
    else
      # Überlappen: Kontextbereiche verschmelzen
      merged_matches.last[:end_idx] = [merged_matches.last[:end_idx], current[:end_idx]].max
    end
  end
  
  # Zusammengeführte Matches ausgeben
  merged_matches.each do |match|
    print "\e[35m" if options[:color]
    puts "#{file}" if !options[:nohead] # Dateikopf ausgeben
    print "\e[0m" if options[:color]
    # Kontextzeilen ausgeben
    context_lines = lines[match[:start_idx]..match[:end_idx]]
    context_lines.each_with_index do |context_line, context_idx|
      line_number = match[:start_idx] + context_idx
      # Übereinstimmungen hervorheben, wenn Farbausgabe aktiviert ist
      highlight = options[:color] ? context_line.gsub(regexp) { |m| "\e[31m#{m}\e[0m" } : context_line
      print "\e[35m" if options[:color]
      print file + ":" if options[:nohead]
      print "\e[32m" if options[:color]
      puts "#{line_number}: #{options[:color] ? "\e[0m" + highlight : highlight}"
    end
  end
end
end
