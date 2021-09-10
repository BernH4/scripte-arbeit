require 'fileutils'
require 'pry'

FileUtils.rm_rf('angepasste_zsp')
Dir.mkdir('angepasste_zsp')
FileUtils.rm_rf('tmp')

# Create work dir and convert line endings to unix \n
Dir.mkdir('tmp')
FileUtils.copy_entry('anzupassende_scripte', 'tmp')
system('dos2unix -q tmp/*')

filecounter = 0
Dir.glob('anzupassende_scripte/*') do |file|
  filecounter += 1
  basename = File.basename(file)
  change_counter = 0

  # FileUtils.cp(file, "angepasste_zsp/#{basename}")
  file_arr = File.readlines("tmp/#{basename}")
  printf("\n\e[1;32m%-14s\e[m %-8s %s\n", 'Bearbeite:', basename, '')
  new_file_arr = []
  previous_matched = false

  file_arr.each_with_index do |line, idx|
    if previous_matched
      previous_matched = false
      next
    end
    # puts idx, line
    if line.include?('_script.')
      if file_arr[idx + 1].match(/\/\*[0-9]+:[0-9]+ ?Uhr.*\*\//)
        new_line = file_arr[idx].chomp + '     ' + file_arr[idx + 1]
        new_file_arr <<  new_line
        printf("\e[1;33m%-14s\e[m %s", 'Angepasst:', new_line)
        change_counter += 1
        previous_matched = true
      else
        new_file_arr << file_arr[idx]
        printf("\n\e[1;31m%-14s\e[m %-8s %s\n", 'Info:', 'Zeile ohne Uhrzeitkommentar gefunden (wurde nicht bearbeitet):', '')
        printf("\e[1;31m%-14s\e[m %-8s %s\n", '', 'Script:', basename)
        printf("\e[1;31m%-14s\e[m %-8s %s\n", '', 'Zeile:', (idx + 1).to_s)
        printf("\e[1;31m%-14s\e[m %-8s %s\n", '', 'Befehlszeile:', file_arr[idx].chomp)
        printf("\e[1;31m%-14s\e[m %-8s %s\n", '', 'Theoretische Kommentarzeile: ', file_arr[idx + 1])
      end
    else
      new_file_arr << file_arr[idx]
    end
  end

  File.open("angepasste_zsp/#{basename}", 'w+') do |file|
    file.puts(new_file_arr)
  end

  printf("\n\e[1;32m%-14s\e[m %-8s %s\n", 'Abgeschlossen:',basename , '')
  printf("\e[1;32m%-5s\e[m %-8s %s\n", '',"Kommentare verschoben: " , "#{change_counter}")
  # puts "Anzahl gefundener Kommentare: #{File.read("anzupassende_scripte/#{basename}").scan(/\/\*.*\*\//).count}"
end

# convert back to windows line endings \r\n
system("find angepasste_zsp/ -type f | xargs unix2dos -q")
FileUtils.rm_rf('tmp')

printf("\n\e[1;35m%-14s\e[m %-8s %s\n", 'Info:', "Alle Scripte (auch nicht angepasste) sind im Ortner 'angepasste_zsp' zu finden." , '')
