require 'json'
require 'bundler/setup'

Bundler.require(:default)
Dotenv.load

class Analyzer
  attr_reader :path

  def initialize(path)
    @path = path
  end

  def id
    @id ||= html.css('footer a')[1].attribute_nodes.first.value.split('/').last
  end

  def migration_identifier
    "#{ENV['IDENTIFIER']}-post-#{id}"
  end

  def date
    html.css('.dt-published').first.attribute_nodes.last.value
  end

  def image
    html.css('.graf-image').first['src']
  rescue
    ''
  end

  def title
    @title ||= html.css('.p-name').first.text
  end

  def original_path
    url.split('/').last
  end

  def url
    @url ||= html.css('.p-canonical').first.attribute_nodes.first.value
  end
  
  def hash
    {
      migration_identifier: migration_identifier,
      created_at: date,
      updated_at: date,
      localizations: {
        fr: {
          migration_identifier: "#{migration_identifier}-fr",
          aliases: [
            original_path
          ],
          title: title,
          featured_image: {
            url: image
          },
          published: true,
          published_at: date,
          created_at: date,
          updated_at: date,
          blocks: blocks
        }
      }
    }
  end

  def blocks
    @title_index = 0
    @chapter_index = 0
    @image_index = -1 # Featured image is first
    @video_index = 0
    @embed_index = 0
    @testimonial_index = 0
    @blocks = []
    @chapter_content = ''
    html.css('.section-inner .graf').each_with_index do |child, index|
      case child.name
      when 'h3'
        # Nothing, title
      when 'p'
        if child.to_html.include?('www.youtube.com')
          flush_chapter
          add_video child.children.first['src']
        elsif child.to_html.include?('<iframe')
          flush_chapter
          add_embed child.children.first.to_html
        elsif child.children.first.name == "strong"
          flush_chapter
          add_title child.text
        else
          @chapter_content += child.to_html
        end
      when 'ul'
        @chapter_content += child.to_html
      when 'ol'
        @chapter_content += child.to_html
      when 'blockquote'
        flush_chapter
        add_testimonial child.to_html
      when 'figure'
        # First image is featured_image
        if @image_index == -1
          @image_index += 1
          next
        end
        flush_chapter
        add_image child.children.first['href']
      end
    end
    flush_chapter
    @blocks
  end

  protected

  def position
    @blocks.count
  end

  def flush_chapter
    add_chapter @chapter_content if @chapter_content != ''
  end

  def add_title(text)
    @blocks << {
      template_kind: 'title',
      migration_identifier: "#{migration_identifier}-title-#{@title_index}",
      position: position,
      title: text,
      data: {
        layout: 'classic'
      }
    }
    @title_index += 1
  end

  def add_chapter(text)
    clean_text = text.gsub(" class=\"spip_out\"", '')
                    .gsub(" class=\"spip\"", '')
    @blocks << {
      template_kind: 'chapter',
      migration_identifier: "#{migration_identifier}-chapter-#{@chapter_index}",
      position: position,
      data: {
        text: clean_text
      }
    }
    @chapter_content = ''
    @chapter_index += 1
  end

  def add_image(url)
    return if url.nil?
    @blocks << {
      template_kind: 'image',
      migration_identifier: "#{migration_identifier}-image-#{@image_index}",
      position: position,
      data: {
        url: url
      }
    }
    @image_index += 1
  end

  def add_video(url)
    return if url.nil?
    url = url.gsub('//www.youtube.com', 'https://www.youtube.com')
    @blocks << {
      template_kind: 'video',
      migration_identifier: "#{migration_identifier}-video-#{@video_index}",
      position: position,
      data: {
        url: url
      }
    }
    @video_index += 1
  end

  def add_embed(code)
    @blocks << {
      template_kind: 'video',
      migration_identifier: "#{migration_identifier}-embed-#{@embed_index}",
      position: position,
      data: {
        code: code
      }
    }
    @embed_index += 1
  end

  def add_testimonial(text)
    @blocks << {
      template_kind: 'testimonials',
      migration_identifier: "#{migration_identifier}-testimonial-#{@testimonial_index}",
      position: position,
      data: {
        layout: 'carousel',
        testimonials: [
          {
            text: text
          }
        ]
      }
    }
    @testimonial_index += 1
  end

  def file
    @file ||= File.read path
  end

  def html
    @html ||= Nokogiri::HTML::DocumentFragment.parse file
  end
end

SOURCE_DIRECTORY = './imported/'

def convert_id(id)
  puts "Convert id #{id}"
  convert_path "#{SOURCE_DIRECTORY}#{id}.html"
end

def convert_path(path)
  puts "Convert path #{path}"
  analyzer = Analyzer.new path
  puts JSON.pretty_generate(analyzer.hash)
  File.write("converted/#{analyzer.id}.json", analyzer.hash.to_json)
end

def convert_directory
  puts "Convert directory"
  Dir["#{SOURCE_DIRECTORY}*.html"].each do |path|
    convert_path path
  end
end

ARGV.empty? ? convert_directory
            : convert_id(ARGV.first)