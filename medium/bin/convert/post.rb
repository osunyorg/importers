
class Post
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

  def first_image
    @first_image ||= html.css('.graf--figure').first
  end

  def image_url
    first_image.css('.graf-image').first['src']
  rescue
    ''
  end

  def image_credit
    credit = first_image.css('figcaption').children.to_html
    "<p>#{credit}</p>"
  rescue
    ''
  end

  def title
    @title ||= html.css('.p-name').first.text
  end

  def subtitle
    @subtitle ||= html.css('.graf-subtitle').first&.text
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
          subtitle: subtitle,
          featured_image: {
            url: image_url,
            credit: image_credit
          },
          published: true,
          published_at: date,
          created_at: date,
          updated_at: date,
          blocks: blocks.to_hash
        }
      }
    }
  end

  protected

  def blocks
    @blocks ||= Blocks.new(html, migration_identifier)
  end

  def file
    @file ||= File.read path
  end

  def html
    @html ||= Nokogiri::HTML::DocumentFragment.parse file
  end
end
