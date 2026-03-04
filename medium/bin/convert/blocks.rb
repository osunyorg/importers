class Blocks
  attr_reader :html, :migration_identifier

  def initialize(html, migration_identifier)
    @html = html
    @migration_identifier = migration_identifier
  end

  def to_hash
    @title_index = 0
    @chapter_index = 0
    @image_index = -1 # Featured image is first
    @video_index = 0
    @embed_index = 0
    @testimonial_index = 0
    @blocks = []
    @chapter_content = ''
    html.css('.graf').each_with_index do |child, index|
      case child.name
      when 'h3'
        # Nothing, title
      when 'h4'
        flush_chapter
        add_title child.text
      when 'p'
        @chapter_content += child.to_html
      when 'ul'
        @chapter_content += child.to_html
      when 'ol'
        @chapter_content += child.to_html
      when 'blockquote'
        flush_chapter
        add_testimonial child.to_html
      when 'div'
        @chapter_content += child.to_html
      when 'figure'
        if child.to_html.include?('www.youtube.com')
          flush_chapter
          add_video child.children.first.attribute_nodes.first.value
        elsif child.to_html.include?('<iframe')
          flush_chapter
          add_embed child.children.first.to_html
        else
          # First image is featured_image
          if @image_index == -1
            @image_index += 1
            next
          end
          flush_chapter
          add_image child
        end
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

  def add_image(child)
    image = child.css('.graf-image').first
    return if image.nil?
    url = image['src']
    id = Media.for(url)
    credit = "<p>#{child.css('figcaption').text}</p>"
    @blocks << {
      template_kind: 'image',
      migration_identifier: "#{migration_identifier}-image-#{@image_index}",
      position: position,
      data: {
        id: id,
        credit: credit
      }
    }
    @image_index += 1
  end

  def add_video(url)
    return if url.nil?
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
end