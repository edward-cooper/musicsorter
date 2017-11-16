This is a script to take info from a CSV file and put it into flac audio tags using the metaflac program.

There is an existing 'exiftool' program that will read audio tag information (artist, title, album, etc) from flac files and write to a CSV. But it won't do this in reverse. So I wrote a script to do this via metaflac. (I did this because I wanted to be able to edit tag information using any machine running Excel, rather than having to be sitting at my machine with the music.)

Tag names are arbritary. The first column of the CSV file needs to contain the filename and relative path (from the directory where the script is being run). If the user wants to, they can wipe out existing tag names entirely, so that tags within the flac files contain _only_ the information found in the CSV. Do this by setting 'violent_mode' to true. Alternatively, it is possible to add or edit only those filenames that are mentioned in the CSV. The latter scenario is useful if you want to add a tag to all your files (such as the year of a track's recording), or if you are happy with most of the existing tags, but want to change those mentioned in the file.

See comments in filemover.rb for descriptions of sample output.
