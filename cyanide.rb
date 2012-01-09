require 'open-uri'
require 'sinatra'
require 'nokogiri'
require 'feedzirra'
require 'thread'

enable :logging
set :environment, :development
set :source, 'http://feeds.feedburner.com/Explosm'
set :title_regexp, /(\d{2})\.(\d{2})\.(\d{4})/

get '/' do
  content_type 'application/rss+xml'
  @feed = build_feed
  haml(:rss, :format => :xhtml, :escape_html => true, :layout => false)
end

def build_feed
  feed = source_rss
  {
    :title => feed.title,
    :link => feed.url,
    :description => feed.description,
    :feed_url => feed.feed_url,
    :items => feed_items(feed)
  }
end

def source_rss
  Feedzirra::Feed.fetch_and_parse(settings.source)
end

def feed_items(feed)
  items = []
  mutex = Mutex.new
  feed.entries.map do |entry|
    Thread.new do
      item = build_item(entry)
      mutex.synchronize { items << item }
    end
  end.each { |t| t.join }
  items.sort { |a, b| b[:pub_date] <=> a[:pub_date] }
end

def build_item(entry)
  {
    :src => fetch_image_src(entry.url),
    :title => build_item_title(entry.title),
    :link => entry.url,
    :guid => entry.entry_id,
    :pub_date => entry.published
  }
end

def fetch_image_src(url)
  doc = Nokogiri::HTML(open(url))
  img = ''
  doc.css('#maincontent img[alt="Cyanide and Happiness, a daily webcomic"]').each do |i|
    img = i.attributes['src']
  end
  return img
end

def build_item_title(title)
  m = settings.title_regexp.match(title)
  return title unless m
  "#{m[3]}-#{m[1]}-#{m[2]}"
end