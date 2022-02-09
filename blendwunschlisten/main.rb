# Verbesserungsmöglichkeiten:
# Abfrage welche Gebäude gebraucht werden
# Gebäude direkt in Ortner S01-S08 + S21 verschieben (Abfrage vorher ob von Energiesystem oder Gebäudesystem)
# error wenn mehr als eine datei in sicx_data
#
# Spezialfall: _354/Z4AG2A/S05/HEBEANLAGEN/BA_PROZESS/WARTUNGSSCHALTER_TOC
# require 'pry-byebug'
require 'fileutils'
# require 'ap'

$seperator = "|" #CSV muss mit Pipe (|) getrennt abgespeichert werden! (Kommas oder Semicolons kommen bereits in der Excel Datei vor)

#### HIER DATEINAMEN ANPASSEN #####
$csv_geb_sys = "DesigoCC-AS-Zuordnung-Gebäude-V03_Anpassung-Siemens_20220118.csv"
$csv_energy_sys = "DesigoCC-AS-Zuordnung-Energie-V03.csv"
###################################

puts "Falls ein Fehler auftritt bitte kontrollieren ob csv Datei mit '|' als Seperator abgespeichert wurde."
puts

FileUtils.rm_rf('fertige_blendwuensche')
FileUtils.rm_rf('tmp')

Dir.mkdir('sicx_data') unless Dir.exist?('sicx_data')

# Create work dir and convert line endings to unix \n
Dir.mkdir('tmp')
FileUtils.copy_entry('sicx_data', 'tmp')
system('dos2unix -q tmp/*')

Dir.mkdir('fertige_blendwuensche') unless Dir.exist?('fertige_blendwuensche')

files_generated = 0

def get_needed_dir(line, energie, geb_info)
  name = if energie
           info = line.split('/')[0..1]
           info.first.delete!('_')
           info.join('_')
         else
           line.split('/').first
         end
  # binding.pry
  begin
    system = energie ? 'Energiesystem' : 'Gebäudesystem'
    dir = File.join(system, geb_info[name][:month], geb_info[name][:server])
  rescue StandardError
    puts "Konnte #{line.chomp} nicht Zuordnen, verwende Ortner 'Rest'"
    dir = 'rest'
  end
  dir
end

def parse_bearbeitungslisten
  data_geb = File.readlines("bearbeitungslisten/#{$csv_geb_sys}", encoding: 'iso-8859-1')[3..-1]
  data_energy = File.readlines("bearbeitungslisten/#{$csv_energy_sys}", encoding: 'iso-8859-1')[3..-1]
  parsed_geb = parse_bearbeitungsliste(data_geb, geb_sys: true)
  parsed_energy = parse_bearbeitungsliste(data_energy, geb_sys: false)
  parsed_geb.merge(parsed_energy)
end

def parse_bearbeitungsliste(data, geb_sys:)
  gebs = {}
  data.each do |line|
    line.encode!('utf-8')
    cols = line.split($seperator)
    if geb_sys
      geb = cols.first.delete('*')
      next if geb.nil?

      gebs[geb] = { month: cols[6].delete(' '), server: cols[4] }
    else
      geb = cols[1].delete('_').gsub('/', '_')
      next if geb.nil?

      gebs[geb] = { month: cols[6].delete(' '), server: cols[4] }
    end
  end
  gebs
end

def data_ok?(geb_info)
  puts "Bitte kontrollieren ob die Daten (für benötigten Monat) richtig eingelesen wurden:"
  puts "Achtung Energiesystem ist getrennt weiter unten aufgelistet"
  sleep(5.0)

  prev_month = nil
    geb_info.each do |geb, value|
      month = value[:month]
      next if month.include?("entfällt")
      puts month unless month == prev_month
      puts "   #{geb} -> #{value[:server]}" unless geb == ""
      prev_month = month
    end
  puts
  puts "Falls die Daten falsch sind wurde die CSV möglicherweiße nicht mit | als Seperator abgespeichert"
  puts "Abbruch mit STRG-C weiter mit ENTER"
  input = STDIN.gets
  exit unless input == "\n"
end

geb_info = parse_bearbeitungslisten

# Auskommentiert, da wahrscheinlich einfach Daten Direkt im Ortner zu kontrollieren.
# data_ok?(geb_info)

Dir['tmp/*'].each do |complete_file|
  filename = File.basename(complete_file)
  energie = filename.include?('energie')
  complete_file_arr = File.readlines(complete_file)

  curr_file_arr = []
  curr_target_dir = ''
  filename = ''
  special = false
  enable_write = false

  complete_file_arr.each_with_index do |line, _idx|
    # Spezialfall: _354/Z4AG2A/S05/HEBEANLAGEN/BA_PROZESS/WARTUNGSSCHALTER_TOC
    # Keine Ahnung was das ist aber muss übersprungen werden..
    #
    if line.include?('WARTUNGSSCHALTER')
      special = true
      next
    end

    if special
      if line.include?('Betriebsstd_OG_Zust')
        puts "Spezialfall: _354/Z4AG2A/S05/HEBEANLAGEN/BA_PROZESS/WARTUNGSSCHALTER_TOC (Scheibe: Januar 2022) wurde übersprungen"
        special = false
        next
      else
        next
      end
    end

    if line.include?('EVENT_WEGE')
      enable_write = true
      filename_arr = line.split('/')
      filename_arr.first.delete!('_')
      # filename_arr[1].delete!('Z').sub!('AG', '') ##comment out for full ag name
      filename = filename_arr[0..2].join('_').concat('.txt')
      curr_file_arr = ['~', nil, nil, line]
    elsif line.chomp.empty? && enable_write
      curr_file_arr.push('~')
      target_dir = get_needed_dir(curr_file_arr[3], energie, geb_info)
      FileUtils.mkdir_p("fertige_blendwuensche/#{target_dir}") unless Dir.exist?("fertige_blendwuensche/#{target_dir}")
      File.open("fertige_blendwuensche/#{target_dir}/#{filename}", 'w+') do |file|
        file.puts(curr_file_arr)
      end
      enable_write = false
      files_generated += 1
    elsif enable_write
      curr_file_arr << line
    end
  end
end

# convert back to windows line endings \r\n
system("find fertige_blendwuensche/ -type f | xargs unix2dos -q")

FileUtils.rm_rf('tmp')

puts "\n#{files_generated} Blendwuschlisten sind im Ortner 'fertige_blendwuensche' zu finden."
