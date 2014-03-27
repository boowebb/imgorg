# script will move images to folders based on YEAR / MONTH / DAY within supplied <dir>
#
# files with same name will be moved in under the scheme <file>_1, <file>_2, etc
#
# if file info cannot be read image will be moved to <dir>/unknown
#
# empty folders at the end of the process will be moved to <dir>/delete
#
# arguments
# - directory to process (required)
# - target directory (optional - defaults to first argument)

require 'find'
require 'fileutils'
require 'mini_exiftool'
require 'ruby-debug'    # provided in case need to debug

if ARGV.empty?
  puts "script requires directory to process"
  exit
end

# only argument required is src_dir - destination is source unless otherwise specified
src_dir  = ARGV[0]
dest_dir = ARGV[1] || src_dir

moved_ct  = 0
stayed_ct = 0

puts
puts "moving images to YYYY/MM/DD directory structure"
puts

# recurse over all files in a directory
Find.find(src_dir).each do |img_path|

  # find gets both dir and files - only process files
  if File.file?(img_path)
    begin
      img_data = MiniExiftool.new(img_path)

      # get image data from meta data in the following order
      img_dt = img_data['DateTimeOriginal'] || img_data['CreateDate'] || img_data['ModifyDate'] || img_data['FileModifyDate']

      # dump to console if you cannot get date from file (not guaranteed to be an image file)
      if img_dt.nil? || img_dt == ""
        # debugger
        # MiniExiftool.all_tags.select { |t| t =~ /date/i }.map { |x| "#{x} : #{img_data[x]}" }

        puts "** not able to get date from file: #{img_path}"
        next
      end

      new_img_path = "#{dest_dir}/#{img_dt.year}/#{"%02d" % img_dt.month}/#{"%02d" % img_dt.day}/#{img_path.split("/").last}".gsub!('//', '/')

      if img_path == new_img_path
        # just leave image in place if it's where it's supposed to be
        stayed_ct += 1
#        puts "-- image does not need to be moved: #{img_path}"
      else
        idx = 0

        # increment file (file_0.gif, file_1.gif, etc) if it exists as named in destination
        while File.exists?(new_img_path)
          idx += 1
          nia = new_img_path.split('.')
          nia[-2] += "_#{idx}"
          new_img_path = nia.join(".")
        end

        nda = new_img_path.split('/')
        nda.pop

        new_dir = nda.join('/')

        FileUtils.mkdir_p new_dir
        FileUtils.mv img_path, new_img_path

        moved_ct += 1
#        puts ".. moved image #{img_path} to #{new_img_path}"
      end
    rescue Exception => e
      puts "** #{e} : #{img_path}"
    end
  end

end

puts
puts "done with move"
puts ".. moved #{moved_ct} image files"
puts ".. kept #{stayed_ct} images in current location"
