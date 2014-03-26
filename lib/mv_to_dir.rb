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
require 'ruby-debug'

if ARGV.empty?
  puts 'script requires directory to process'
  exit
end

src_dir  = ARGV[0]
dest_dir = ARGV[1] || src_dir

# recurse over all files in a directory
Find.find(src_dir).each do |img_path|

  if File.file?(img_path)
    begin
      img_data = MiniExiftool.new(img_path)

      img_dt = img_data['DateTimeOriginal'] || img_data['CreateDate'] || img_data['ModifyDate'] || img_data['FileModifyDate']
      img_dt = img_dt unless img_dt.nil?

      if img_dt.nil? || img_dt == ""

        debugger
        # MiniExiftool.all_tags.select { |t| t =~ /date/i }.map { |x| "#{x} : #{img_data[x]}" }

        puts "** not able to get date from file: #{img_path}"
        next
      end

      new_img_path = "#{dest_dir}/#{img_dt.year}/#{"%02d" % img_dt.month}/#{"%02d" % img_dt.day}/#{img_path.split("/").last}".gsub!('//', '/')

      if img_path == new_img_path
#        puts "-- image does not need to be moved: #{img_path}"
      elsif File.exists?(new_img_path)
        puts "!! image already exists in new location: #{img_path}"
      else
        nda = new_img_path.split('/')
        nda.pop

        new_dir = nda.join('/')

        FileUtils.mkdir_p new_dir
        FileUtils.mv img_path, new_img_path

#        puts ".. moved image #{img_path} to #{new_img_path}"
      end
    rescue Exception => e
      puts "** #{e} : #{img_path}"
    end
  end

end
