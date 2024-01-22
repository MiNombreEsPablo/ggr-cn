# lib/crawling_service.rb
# frozen_string_literal: true

# gem 'selenium-webdriver', '4.10.0'
# gem 'webdrivers', '5.3.1'

# require 'nokogiri'
# require 'watir'
# require 'webdrivers'

class CrawlingService
  attr_reader :results

  def initialize(attributes = {})
    @search_topic = attributes[:search_topic]
    @results = []
    @ongoing = true
  end

  def crawl
    browser = Watir::Browser.new :chrome, options: { args: %w[--remote-debugging-port=9222] }
    browser.driver.manage.window.maximize
    url = "https://www.china-news.co.jp/category.html?content=#{@search_topic}"
    browser.goto(url)
    while @ongoing
      wait_for_preloader_to_disappear(browser)
      html = browser.html
      doc = Nokogiri::HTML.parse(html, nil, 'utf-8')
      # get results
      get_articles(doc)
      next_page(browser)
    end
    browser.close
    @results.reject { |result| result.include?('/list/') }
  end

  private

  def next_page(browser)
    # go to next page
    next_btn = browser.element(css: 'li.next')
    next_disabled = browser.element(css: 'li.next.disabled').present?
    if next_btn.present? && !next_disabled
      browser.execute_script('arguments[0].click();', next_btn)
    else
      @ongoing = false
    end
  end

  def get_articles(doc)
    articles = doc.css('.news-post.news-feature-mb li')
    articles.each do |article|
      @results << {
        url: "https://www.china-news.co.jp/#{article.css('a').attr('href').text}",
        title: article.css('a').text.strip,
        author: article.css('.author').text.strip,
        datetime: article.css('.data-create-time').text.strip
      }
    end
  end

  def wait_for_preloader_to_disappear(browser)
    wait_condition = lambda do
      preloader_div = browser.div(class: 'preloader')
      preloader_div.style('display') == 'none'
    end

    browser.wait_until(timeout: 60, message: 'Timeout waiting for preloader to disappear') { wait_condition.call }
  end
end
