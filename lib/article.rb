# lib/article.rb
# frozen_string_literal: true

class Article
  attr_accessor :source, :date, :parsed, :article_text
  attr_reader :url, :title

  def initialize(attributes = {})
    # title,date,time,source,article_text,url
    @title = attributes[:title] || attributes['title']
    @date = attributes[:date] || attributes['date']
    @time = attributes[:time] || attributes['time']
    @source = attributes[:source] || attributes['source'] || 'AFP'
    @article_text = attributes[:article_text] || attributes['article_text']
    @url = attributes[:url] || attributes['url']
    @parsed = attributes[:parsed] == 'true' || attributes['parsed'] == 'true' || attributes[:parsed] == true || attributes['parsed'] == true || false
    @author = attributes[:author] || attributes['author']
  end

  def self.attribute_names
    %w[title date time source article_text url parsed author]
  end

  def attributes
    {
      'title' => @title,
      'date' => @date,
      'time' => @time,
      'source' => @source,
      'article_text' => @article_text,
      'url' => @url,
      'parsed' => @parsed,
      'author' => @author
    }
  end
end
