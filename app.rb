require 'sinatra'
require 'haml'
require 'feed-normalizer'
require 'open-uri'
require 'digest/md5'

class AddGuid < Sinatra::Base
  enable :show_exceptions

  get '/' do
    @options = get_options(params)
    haml :index
  end

  get '/feed' do
    options = get_options(params)
    feed = FeedNormalizer::FeedNormalizer.parse open(options[:url])
    feed.entries.each do |entry|
      # guidに相当する文字列を渡されたオプションからよしなに生成する。
      seed = ''
      if options[:link]
        seed += entry.url
      end
      if options[:title]
        seed += entry.title
      end
      if options[:description]
        seed += entry.content
      end
      if options[:date]
        seed += entry.date_published.to_s
      end
      if options[:guid]
        seed += entry.id ? entry.id : ''
      end

      # entry.idを存否の確認をせずに上書きする。
      entry.id = Digest::MD5.hexdigest(seed)
    end

    rss = RSS::Maker.make('2.0') do |rss|
      rss.channel.title = feed.title
      rss.channel.description = feed.description
      rss.channel.link = "#{to('/')}?#{request.query_string}"

      feed.entries.each do |entry|
        item = rss.items.new_item
        item.title = entry.title
        item.link = entry.url
        item.guid.content = entry.id
        item.guid.isPermaLink = false
        item.description = entry.content
        item.date = entry.date_published
      end
    end

    content_type 'application/rss+xml', :charset => 'utf-8'
    rss.to_s
  end

  def get_options(params)
    options = {}

    options[:url] = params[:url]
    [:link, :title, :description, :date, :guid].each do |key|
      options[key] = (params[key] == 'on')
    end

    return options
  end
end
