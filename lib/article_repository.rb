# lib/article_repository.rb
# frozen_string_literal: true

gem 'selenium-webdriver', '4.10.0'
gem 'webdrivers', '5.3.1'

require 'csv'
require 'nokogiri'
require 'watir'
require 'webdrivers'
require 'open-uri'

require_relative 'article'
require_relative 'parsing_service'
require_relative 'crawling_service'

class ArticleRepository
  def initialize(attributes = {})
    @articles = []
    @path = './results/articles.csv'
    load_csv
    @parser = ParsingService.new
    @crawler = CrawlingService.new(search_topic: attributes[:search_topic])
    @results = []
  end

  def all
    @articles
  end

  def add(result, browser)
    new_article = Article.new(@parser.parse(result, browser))
    @articles << new_article
  end

  def start
    @results = crawl_list.uniq
    total = @results.size
    processed = 0
    browser = Watir::Browser.new :chrome, options: { args: %w[--remote-debugging-port=9222] }
    @results.each do |result|
      p result[:url]
      add(result, browser)
      processed += 1
      puts "Progress #{format('%.2f', 100 * processed / total.to_f)}%"
      puts "#{processed} out of #{total} articles scraped"
    end
    browser.close
    save_csv
  end

  def update
    browser = Watir::Browser.new :chrome, options: { args: %w[--remote-debugging-port=9222] }
    non_parsed.each do |article|
      p article.url
      new_attributes = @parser.parse({ url: article.url }, browser)
      article.article_text = new_attributes[:article_text]
      article.parsed = new_attributes[:parsed]
    end
    browser.close
    save_csv
  end

  def non_parsed
    # return every non parsed article
    @articles.select { |article| article.parsed == false }
  end

  def save_csv
    raise 'No articles to save' if @articles.empty?

    CSV.open(@path, 'w',
             write_headers: true,
             headers: Article.attribute_names,
             encoding: 'UTF-8') do |csv|
      @articles.each { |item| csv << item.attributes.values }
    end
  end

  private

  def crawl_list
    @crawler.crawl
  end

  def load_csv
    if File.exist?(@path)
      @articles.clear # Clear the existing articles array
      CSV.foreach(@path, headers: :first_row, header_converters: :symbol, encoding: 'UTF-8') do |row|
        # Check if an article with the same URL already exists
        @articles << Article.new(row)
      end
    else
      # Create an empty CSV file if it doesn't exist
      folder_path = File.dirname(@path)
      FileUtils.mkdir_p(folder_path) unless File.exist?(folder_path)

      File.open(@path, 'w') {} # Create an empty file
    end
  end
end
