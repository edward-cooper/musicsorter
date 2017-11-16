#!/usr/bin/ruby -w


########################################################
# OPTIONS:
# violent_mode removes all tags and replaces them with those in the CSV file. It does not discriminate between tags in the CSV file: it will apply ALL tags in the CSV file to the flac files. So there is no need to edit 'include_list' (below) if you're in violent mode: in effect, everything is in the include list.
# nonviolent mode (ie violent_mode is false) removes only those tags in the include list, and replaces them with those in the CSV file. Tags not in the include_list are unaffected, regardless of what the CSV file contains.
violent_mode = false
# test_mode displays the command we would have executed, but doesn't execute it.
test_mode = true
#remove colons from filenames. This is here because I previously wondered whether it was affecting metaflac's operation. I now don't believe it is, so this can almost certainly be left as false.
remove_colons = false 
# Below: the 'standard list' of tags we want to edit. This is handy as a defautlt for the next option (include list).
standard_list = %w(Artist Composer Performer DiscNumber Album Title Date Genre TrackNumber TrackTotal CDDB Comment Duration)
# Below: the 'include list'. In nonviolent mode, we will only change tags in the include list. 
include_list = %w(Artist Title)
# Below: set include list to standard list if we want to. Otherwise, standard_list is ignored.
# include_list = standard_list
########################################################
# SAMPLE OUTPUT FILES:
# sample_file_violent_mode: Violent mode = true ; include list is irrelevant
# sample_output_standard_list.txt: Violent mode = false ; include list is set to standard list
# sample_output_short_list.txt: Violent mode = false ; include list is set to Artist and title.
#########################################################


inputFile = ARGV.shift.chomp
ARGV.clear
require 'csv'
# Below: arr_of_arrs is just what it suggests. Each line in the CSV is put into an array, with the option of lines as the elements of that array. Then we just create an array of all those line-arrays.
arr_of_arrs = CSV.read(inputFile)

# Below: grab only the title line of the file, which contains the name of the flac fields we're editing.
firstline = arr_of_arrs.shift
# Below: The first element of any line-array is the filename (see CSV file). We want to remove that, so that firstline contains a list of our field names, and nothing else.
firstline.shift

# The 'include_numbers' array will contain the array positions of those fields we want to include.
include_numbers = Array.new

# Below block: if we're not in violent mode, then make a list of fields to edit, which is stored in include_numbers. Also, warn if something in the include list is not in the CSV input file, or vice-versa.
# (If we are in violent mode, then we don't care what's on our edit list. We are going to remove all tags, and replace them with whatever's in the CSV. So we can jump straight down to 'beginning of actual operation', below.)
if (violent_mode == false) then
  i = 0

  # Below loop: make the actual list of fields to include, based on the array positions in firstline of CSV. Only include those titles that are _also_ in the include_list array (as set at the top of this file).
  firstline.each do | current_field |
    include_list.each do | current_test |

      if ( current_field.upcase == current_test.upcase )
        include_numbers.push(i)
      end
    end
    i = i + 1
  end
  
  i = 0

  # Below loop: check to see which fields, contained in the CSV, are NOT contained in the include_list array. If there are any such fields, warn about this, list them, and give the user the chance to quit.
  something_excluded = false
  excluded_fields = Array.new
  firstline.each do | current_field |
    if (not (include_numbers.include?(i)))
      something_excluded = true
      excluded_fields.push(current_field)
    end
    i = i + 1
  end
  if (something_excluded == true) then
    warn "Excluding the following fields in the file, as they are not in the include list:\n"
    excluded_fields.each do | current |
      warn current
      
    end
    warn "Is this ok? Press Ctrl-C to quit or enter to continue...\n"
    gets
  end

  # Below loop: Do the opposite of what we just did. Check to see which fields, contained in the include_list array, are NOT contained in the CSV file. If there are any such fields, then warn, list, and give user chance to quit.
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

# ###############################################
# End of checking. 
# Beginning of actual operation.
# ###############################################

# Loop through the array of arrays (which is described at the top of this file).
arr_of_arrs.each do | current_line |
  # Below: start with a clean command.
  current_command = ""
  # Below: the file name is the first element of each line array.
  current_file = current_line.shift
  # BELOW: when a filename includes quotes, ensure we prefix them with a backslash so metaflac knows it should take them literally. 
  current_file.gsub!(/"/,'\"')
  remove_colons and current_file.gsub!(/:/,'')
  i = 0
  # BELOW: add remove-tag string entries if BOTH are true: a) we are in nonviolent mode (no need to do it in violent mode - see below); b) the tag is set to be included in our list. Add set-tag entries if one or both of the following are true: a) we are in violent mode; b) the tag is set to be included in our list
  while (i < current_line.length) do
    # BELOW: if current_line[i] isn't null, remove its double quotes entirely. (We do this for track info, not for file names!)
    current_line[i] and current_line[i].gsub!(/\"/,'')
    # Below: in non-violent mode, remove the tag if, and only if, it is mentioned in both our include_list above and the CSV file. (No need to bother removing the tags individually in violent mode, as we will just remove all tags, as shown below.)
    if (violent_mode == false and include_numbers.include?(i) == true) then
        current_command = current_command + "--remove-tag=\"#{firstline[i]}\" "
    end
    # Below: in violent mode, OR if we are including the tag in both lists, then set the tag.
    if (violent_mode == true or include_numbers.include?(i) == true) then 
      current_command = current_command + "--set-tag=\"#{firstline[i]}\"=\"#{current_line[i]}\" " 
    end
    i = i + 1 
  end
  # BELOW: in violent mode, append 'metaflac' to the command, and apply the remove-all-tags option. In both violent and nonviolent mode, append 'metaflac' to the beginning and the current filename to the end.
  if (violent_mode == true) then
    current_command = "metaflac --remove-all-tags #{current_command} \"#{current_file}\" "
  else
    current_command = "metaflac #{current_command} \"#{current_file}\" "
  end

  #BELOW: print the command we're about to run. Let the user scan it if we're in test mode (or you can comment out 'gets' if STDOUT is a file). Otherwise, execute it.
  puts current_command
  if (test_mode == true)
   # gets
  else
    system (current_command)
  end
end 

