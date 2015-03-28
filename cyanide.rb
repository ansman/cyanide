require 'open-uri'
require 'sinatra'
require 'nokogiri'
require 'feedzirra'
require 'cgi'
require 'typhoeus'

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
  hydra = Typhoeus::Hydra.new
  requests = feed.entries.map { |e| Typhoeus::Request.new(e.url) }
  requests.each { |r| hydra.queue(r) }
  hydra.run

  build_items(feed.entries, requests)
end

def build_items(entries, requests)
  entries.zip(requests).map do |item|
    build_item(item[0], item[1])
  end
end

def build_item(entry, request)
  {
    :src => image_src(request.response.body),
    :title => build_item_title(entry.title),
    :link => entry.url,
    :guid => entry.entry_id,
    :pub_date => entry.published
  }
end

def image_src(html)
  doc = Nokogiri::HTML(html)
  img = ''
  doc.css('#main-comic').each do |i|
    img = i.attributes['src']
  end
  return CGI::escapeHTML(img.to_s)
end

def build_item_title(title)
  m = settings.title_regexp.match(title)
  return title unless m
  "#{m[3]}-#{m[1]}-#{m[2]}"
end
