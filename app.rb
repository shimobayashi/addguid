require 'sinatra'
require 'haml'
require 'feed-normalizer'
require 'open-uri'

class AddGuid < Sinatra::Base
  enable :show_exceptions

  get '/' do
    unless params[:url]
      haml :index
    else
      feed = FeedNormalizer::FeedNormalizer.parse open(params[:url])
      feed.entries.each do |entry|
        # entry.idを存否の確認をせずに上書きする。
        # 生成ロジックは後で作り込むことにして、とりあえずurlを突っ込んでおく。
        entry.id = entry.url
      end

      rss = RSS::Maker.make('2.0') do |rss|
        rss.channel.title = feed.title
        rss.channel.description = feed.description
        rss.channel.link = feed.url

        feed.entries.each do |entry|
          item = rss.items.new_item
          item.title = entry.title
          item.link = entry.url
          item.guid.content = entry.id
          # 元のフィードでisPermaLinkがどうだったかは保存されていない気がする(要出典)ので、一律でfalseにしておく
          item.guid.isPermaLink = false
          item.description = entry.content
          item.date = entry.date_published
        end
      end

      content_type 'application/rss+xml', :charset => 'utf-8'
      rss.to_s
    end
  end
end
