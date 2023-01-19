require "fileutils"
require "open-uri"
require "net/http"
require "rmagick"
require "fileutils"
include Magick

zoom = 1
listZoom = [1,2,3,4,5,6,7,8]
TEMP_DIR = "./#{zoom}"
TILES_DIR = "./tiles"
URL0 = "https://cdn.newworldfans.com/newworldmap/09-2022/#{zoom}/xxx/yyy.png"

def invalid?(url)
  uri = URI(url)
  !Net::HTTP.start(uri.host, 443, use_ssl: true){ |http| break http.head uri.path }.instance_of? Net::HTTPOK
end


def build_url(url, x, y)
  url.gsub(/xxx/i, x.to_s).gsub(/yyy/i, y.to_s)
end


// if !File.exists? TEMP_DIR
  // Dir.mkdir TEMP_DIR
// elsif !Dir.empty? TEMP_DIR
  // print "It looks like mapsnatcher didn't close properly. Use backed up files? [Y/n] "
  // FileUtils.rm_f(Dir.glob("#{TEMP_DIR}/*")) if STDIN.gets.chomp =~ /n.*/i
  // puts
// end

  url = URL0

  def get_coords
    print "Enter valid X coordinate [0]: "
    x_in = STDIN.gets.chomp.to_i
    print "Enter valid Y coordinate [0]: "
    y_in = STDIN.gets.chomp.to_i

    print "\nLoading...\r"

    [x_in, y_in]
  end

  valid_x, valid_y = get_coords

  while invalid? build_url(url, valid_x, valid_y)
    puts "Invalid coordinate! Try again."
    puts
    valid_x, valid_y = get_coords
  end

  x_low = x_high = valid_x
  until invalid? build_url(url, x_low - 1, valid_y)
    print "Checking X value: #{x_low}     \r"
    x_low -= 1
  end
  until invalid? build_url(url, x_high + 1, valid_y)
    print "Checking X value: #{x_high}     \r"
    x_high += 1
  end

  y_low = y_high = valid_y
  until invalid? build_url(url, valid_x, y_low - 1)
    print "Checking Y value: #{y_low}     \r"
    y_low -= 1
  end
  until invalid? build_url(url, valid_x, y_high + 1)
    print "Checking Y value: #{y_high}     \r"
    y_high += 1
  end

  puts "Found Coordinate Range: [#{x_low}-#{x_high}], [#{y_low}-#{y_high}]"

  x_range, y_range = (x_low..x_high), (y_low..y_high)

# Use the tile at 0, 0 to calculate final image size
sample = Image.from_blob(URI.open(build_url url, x_range.first, y_range.first).read).first
final_size = {x: sample.columns * x_range.size, y: sample.rows * y_range.size}
format = sample.format
puts "Image found, #{format} size #{final_size[:x]}x#{final_size[:y]}"
puts

dl_counter = 0
dl_total = x_range.size * y_range.size

stitch = ImageList.new
listZoom.each do |z|
	if !File.exists? "./#{z}"
		Dir.mkdir "./#{z}"
	y_range.each do |y|
	  row = ImageList.new
	  x_range.each do |x|
		print "Downloading... [#{dl_counter += 1}/#{dl_total}]\r"
		temp = "#{TEMP_DIR}/#{Dir.mkdir(x) unless Dir.exist? x}_#{y}.#{format.downcase}"
		
		if File.exists? temp
		  img = Image.read(temp).first
		else
		  blob = URI.open(build_url url, x, y).read
		  File.open(temp, "wb") { |f| f.write blob }
		  img = Image.from_blob(blob).first
		row.push img
		end
	  end
	  stitch.push row.append(false)
	end
	stitch.append(true).write "zoom_#{zoom}.png"

puts "\nDone!"
