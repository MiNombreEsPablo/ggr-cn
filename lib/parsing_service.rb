# lib/parsing_service.rb
# frozen_string_literal: true

class ParsingService
  def parse(result, browser)
    content = []
    begin
      url = result[:url]
      browser.goto(url)
      wait_for_preloader_to_disappear(browser)
      html = browser.html
      doc = Nokogiri::HTML.parse(html, nil, 'utf-8')

      title = result[:title]

      datetime = result[:datetime].to_s
      date = datetime.split[0]
      time = datetime.split[1]
      source = result[:author]

      article_selectors = ['#article-detail-area p']
      article_text, parsed = get_article_text(doc, article_selectors)
      author = ''

      content << { title: title, date: date, time: time, source: source, article_text: article_text, parsed: parsed,
                   url: url, author: author }
    rescue OpenURI::HTTPError => e
      content << { url: url, title: title, article_text: "HTTPError: #{e.message}" }
    end
    content.first
  end

  private

  def get_article_text(doc, selectors)
    article_text = nil
    parsed = false

    selectors.each do |selector|
      ps = doc.search(selector)
      ps.search('script').remove

      article_text = ps.map(&:text).join(' ')
      article_text = article_text.force_encoding('UTF-8') unless article_text.valid_encoding?
      if article_text.encoding.name == 'EUC-JP'
        article_text = article_text.encode('UTF-8', 'EUC-JP', invalid: :replace, undef: :replace,
                                                              replace: '')
      end
      article_text = article_text.scrub.strip.delete_prefix('  ')
      parsed = article_text.length.positive?
      break if parsed
    end

    article_text = nil unless parsed
    [article_text, parsed]
  end

  def wait_for_preloader_to_disappear(browser)
    wait_condition = lambda do
      preloader_div = browser.div(class: 'preloader')
      preloader_div.style('display') == 'none'
    end

    browser.wait_until(timeout: 60, message: 'Timeout waiting for preloader to disappear') { wait_condition.call }
  end
end
