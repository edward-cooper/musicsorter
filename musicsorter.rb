#!/usr/bin/ruby -w

inputFile = ARGV.shift.chomp
ARGV.clear
require 'csv'
arr_of_arrs = CSV.read(inputFile)


########################################################
# OPTIONS:
# violent_mode removes all tags and replaces them with those in the CSV file. It does not discriminate between tags in the CSV file: it will apply ALL tags in the CSV file to the flac files.
# nonviolent mode removes only those tags in the include list, and replaces them with those in the CSV file. Tags not in the include_list are unaffected.
violent_mode = false
test_mode = false
remove_colons = false #remove colons from filename
standard_list = %w(Artist Composer Performer DiscNumber Album Title Date Genre TrackNumber TrackTotal CDDB Comment Duration)
include_list = %w(Artist)
# include_list = standard_list
########################################################


firstline = arr_of_arrs.shift
firstline.shift
# firstline now contains a list of our field names.

include_numbers = Array.new

# Below block: if we're not in v. mode, then make a list of fields to include. Also, warn if something in the include list is not in the file, or vice-versa.
if (violent_mode == false) then
  i = 0
  firstline.each do | current_field |
    include_list.each do | current_test |

      if ( current_field.upcase == current_test.upcase )
        include_numbers.push(i)
      end
    end
    i=i+1
  end
  
  i=0
  something_excluded = false
  excluded_fields = Array.new
  firstline.each do | current_field |
    if (not (include_numbers.include?(i)))
      something_excluded = true
      excluded_fields.push(current_field)
    end
    i=i+1
  end
  if (something_excluded == true) then
    warn "Excluding the following fields in the file, as they are not in the include list:\n"
    excluded_fields.each do | current |
      warn current
      
    end
    warn "Is this ok? Press Ctrl-C to quit or enter to continue...\n"
    gets
  end
  something_excluded = false
  excluded_fields = []
  include_list_upper = include_list.map(&:upcase)
  firstline_upper = firstline.map(&:upcase)
  include_list_upper.each do | current |
    if (not (firstline_upper.include?(current)))
      something_excluded = true
      excluded_fields.push(current)

    end
  end
  if (something_excluded == true) then
    warn "Excluding the following fields in the include_list, as they are not in the file:\n"
    excluded_fields.each do | current |
      warn current
      
    end
    warn "Is this ok? Press Ctrl-C to quit or enter to continue...\n"
    gets
  end
  
end

arr_of_arrs.each do | current_line |
  current_command = ""
  current_file = current_line.shift
  # BELOW: when a filename includes quotes, ensure we prefix them with a backslash so metaflac knows it should take them literally. We are NOT renaming files in this script.
  current_file.gsub!(/"/,'\"')
  remove_colons and current_file.gsub!(/:/,'')
  i = 0
  # BELOW: add remove-tag string entries if BOTH are true: a) we are in nonviolent mode (no need to do it in violent mode - see below); b) the tag is set to be included in our list. Add set-tag entries if one or both of the following are true: a) we are in violent mode; b) the tag is set to be included in our list
  while (i < current_line.length) do
    # BELOW: if current_line[i] isn't null, remove its double quotes entirely.
    current_line[i] and current_line[i].gsub!(/\"/,'')
    if (violent_mode == false and include_numbers.include?(i) == true) then
        current_command = current_command + "--remove-tag=\"#{firstline[i]}\" "
    end
    if (violent_mode == true or include_numbers.include?(i) == true) then 
      current_command = current_command + "--set-tag=\"#{firstline[i]}\"=\"#{current_line[i]}\" " 
    end
    i = i + 1 
  end
  # BELOW: in violent mode, apply the remove-all-tags option. 
  if (violent_mode == true) then
    current_command = "metaflac --remove-all-tags #{current_command} \"#{current_file}\" "
  else
    current_command = "metaflac #{current_command} \"#{current_file}\" "
  end

  #BELOW: print the command we're about to run. Let the user scan it if we're in test mode. Otherwise, execute it.
  puts current_command
  if (test_mode == true)
    gets
  else
    system (current_command)
  end
end 

