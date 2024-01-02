# frozen_string_literal: true

require 'csv'

def split_article_text(text)
  return [] if text.nil?

  text.split("\n")
end

def write_row(output_csv, row, headers)
  new_row = {}
  headers.each_with_index do |header, i|
    new_row[header] = row[i]
  end
  output_csv << new_row.values
end

def process_rows(input_csv, output_csv)
  headers = input_csv.first
  output_csv << headers

  seen_urls = []

  input_csv.each do |row|
    url = row[5]

    next if seen_urls.include?(url)

    seen_urls << url

    paragraphs = split_article_text(row[4])

    process_paragraphs(row, paragraphs, output_csv, headers)
  end
end

def process_paragraphs(row, paragraphs, output_csv, headers)
  paragraphs.each do |paragraph|
    next if paragraph.strip.empty?

    new_row = row.dup
    new_row[4] = paragraph.strip
    write_row(output_csv, new_row, headers)
  end
end

# for when the file is run without app.rb
input_csv = CSV.open('./results/articles.csv', 'r', encoding: 'UTF-8')
output_csv = CSV.open('./results/formatted.csv', 'w', encoding: 'UTF-8')

process_rows(input_csv, output_csv)

input_csv.close
output_csv.close
