require 'fileutils'
# require 'pry-byebug'

puts 'Nach welchem String soll gesucht bzw auskommentiert werden? z.B. _221/Z'
search_string = gets.chomp
# search_string = '_221/Z'

puts 'Welcher String soll als Kommentar angehängt werden? z.B. Migration Juni2021'
# suffix = 'Migration Juni2021'
suffix = gets.chomp

Dir.mkdir('angepasste_zsp') unless Dir.exist?('angepasste_zsp')

filecounter = 0
Dir.glob('anzupassende_zsp/*') do |file|
  filecounter += 1
  basename = File.basename(file)
  change_counter = 0

  FileUtils.cp(file, "angepasste_zsp/#{basename}")

  file_arr = File.readlines("angepasste_zsp/#{basename}",  encoding: 'iso-8859-1')
  printf("\e[1;32m%-14s\e[m %-8s %s\n", 'Bearbeite:', basename, '')
  new_file_arr = []

  file_arr.each do |line|
    if line.include?(search_string)
      new_line = line.chomp.delete('#').prepend('#') + ' ' + suffix + ' #'
      new_file_arr << new_line

      printf("\e[1;33m%-14s\e[m %s\n", 'Angepasst:', new_line)
      change_counter += 1

    # elsif line.match?(/^#/)
    #   new_file_arr << line
    # end
    else
      new_file_arr << line
    end
  end

  File.open("angepasste_zsp/#{basename}", 'w+') do |file|
    file.puts(new_file_arr)
  end

  # printf("\n\e[1;32m%-14s\e[m %-8s %s\n", 'Abgeschlossen:',basename , '')
  # printf("\e[1;32m%-5s\e[m %-8s %s\n", '',"Kommentare verschoben: " , "#{change_counter}")
  # printf("\e[1;32m%-5s\e[m %-8s %s\n", '',"Scripte gefunden: " , "#{filecounter}")

  # puts "Anzahl gefundener Kommentare: #{File.read("anzupassende_scripte/#{basename}").scan(/\/\*.*\*\//).count}"
end
