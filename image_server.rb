require 'sinatra'
require 'cgi'

class ImageServer < Sinatra::Base

  #
  # Resize or crop an image at the given url.
  #
  # The path looks like:
  #   crop/50x50/domain.com/yourimage.jpg
  #
  get '/:operation/:dimensions/*' do |operation, dimensions, url|

    url = sanitize_url(url)

    dimensions = sanitize_dimensions(dimensions)

    halt 403 unless url && domain_is_allowed?(url)

    halt 403 unless  %w{ crop resize }.include?(operation)

    headers['Cache-Control'] = 'max-age=31536000'

    image = MiniMagick::Image.open("http://#{ url }")

    send(operation, image, dimensions)

    send_file(image.path, :type => "image/jpeg", :disposition => "inline")
  end

  protected

  #
  # Crop the image
  #
  def crop(image, dimensions)
    image.combine_options do |command|
      command.filter("box")
      command.resize(dimensions + "^^")
      command.gravity("Center")
      command.extent(dimensions)
      command.quality '80'
    end
    image.format("jpg")
  end

  #
  # Resize the image
  #
  def resize(image, dimensions)
    image.combine_options do |command|
      #
      # The box filter majorly decreases processing time without much
      # decrease in quality
      #
      command.filter("box")
      command.resize(dimensions)
      command.quality '80'
    end
    image.format("jpg")
  end

  #
  # encode spaces and brackets
  #
  def sanitize_url(url)
    url.gsub(%r{^https?://}, '').split('/').map {|u| CGI.escape(u) }.join('/')
  end

  #
  # Fix > chars that get encoded to &gt;
  #
  def sanitize_dimensions(dimensions)
    CGI.unescapeHTML(dimensions)
  end

  #
  # Make sure domain is allowed
  #
  def domain_is_allowed?(url)
    true
  end

end
