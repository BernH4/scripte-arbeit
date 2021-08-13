require 'fileutils'
require 'pry-byebug'

puts 'Nach welchem String soll gesucht bzw auskommentiert werden?'
puts 'Mehrere Dateien , getrennt z.B. _221/Z,_121/Z,_353/Z'
search_strings = gets.chomp
# search_strings = '_221/Z,_121/Z'

puts 'Welcher String soll als Kommentar angehängt werden? z.B. Migration Juni2021'
# suffix = 'Migration Juni2021'
suffix = gets.chomp

FileUtils.rm_rf('angepasste_zsp')
FileUtils.rm_rf('tmp')

# Create work dir
Dir.mkdir('tmp')
FileUtils.copy_entry('anzupassende_zsp', 'tmp')
# system('dos2unix -q tmp/*')

Dir.mkdir('angepasste_zsp') unless Dir.exist?('angepasste_zsp')

filecounter = 0
change_counter = 0
Dir.glob('tmp/*') do |file|
  filecounter += 1
  basename = File.basename(file)

  file_arr = File.readlines("tmp/#{basename}",  encoding: 'iso-8859-1')
  printf("\e[1;32m%-14s\e[m %-8s %s\n", 'Bearbeite:', basename, '')

  local_change_counter = 0
  new_file_arr = []

  file_arr.each do |line|
    if search_strings.split(",").any? {|search_part| line.include?(search_part) }
      new_line = line.chomp.delete('#').prepend('#') + ' ' + suffix + ' #'
      new_file_arr << new_line

      printf("\e[1;33m%-14s\e[m %s\n", 'Angepasst:', new_line)
      change_counter += 1
      local_change_counter += 1

    # elsif line.match?(/^#/)
    #   new_file_arr << line
    # end
    else
      new_file_arr << line
    end
  end

  if local_change_counter > 0
    File.open("angepasste_zsp/#{basename}", 'w+') do |file|
      file.puts(new_file_arr)
    end
  # else
  #   FileUtils.rm_rf("angepasste_zsp/#{basename}")
  end

  # printf("\n\e[1;32m%-14s\e[m %-8s %s\n", 'Abgeschlossen:',basename , '')
  printf("\e[1;36m%-14s\e[m %s\n", 'Anzahl in ZSP', local_change_counter) unless local_change_counter == 0
  # printf("\e[1;32m%-5s\e[m %-8s %s\n", '',"Scripte gefunden: " , "#{filecounter}")

  # puts "Anzahl gefundener Kommentare: #{File.read("anzupassende_zsp/#{basename}").scan(/\/\*.*\*\//).count}"
end

FileUtils.rm_rf('tmp')

# system("find angepasste_zsp/ -type f | xargs unix2dos -q")
puts "Änderungen insgesamt: " + change_counter.to_s
puts 'Im Ordner "angepasste_zsp" befinden sich nun nur noch Scripte in denen es Änderungen gab.'
