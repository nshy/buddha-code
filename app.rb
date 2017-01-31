#!/bin/ruby

require 'rubygems'
require 'bundler'

require_relative 'config'
Bundler.require

require 'tilt/erubis'
require 'sinatra/capture'
require 'set'
require 'yaml'

require_relative 'models'
require_relative 'toc'
require_relative 'timetable'
require_relative 'helpers'

set :show_exceptions, false
set :bind, '0.0.0.0'
if settings.development?
  set :static_cache_control, [ :public, max_age: 0 ]
end

helpers TeachingsHelper, CommonHelpers
helpers NewsHelpers, BookHelpers, CategoryHelpers
helpers TimetableHelper

I18n.default_locale = :ru
SiteData = 'data'

before do
  File.open("data/menu.xml") do |file|
    @menu = MenuDocument.new(Nokogiri::XML(file)).menu
  end
  @ya_metrika = SiteConfig::YA_METRIKA
  @extra_styles = []
  @digests = load_digests()
end

not_found do
  map = {}
  File.open("data/compat.yaml") do |file|
    map = YAML.load(file.read)
  end
  obj = request.path
  if not request.query_string.empty?
    obj += '?'
    obj += request.query_string
  end
  goto = map[obj]
  redirect to(goto) if not goto.nil?
  "not found"
end

get /.+\.(jpg|gif|swf|css)/ do
  if settings.development?
    cache_control :public, max_age: 0
  end
  send_file "data/#{request.path}"
end

get /.+\.(doc|pdf)/ do
  if settings.development?
    cache_control :public, max_age: 0
  end
  send_file "data/#{request.path}", disposition: :attachment
end

get '/archive/' do
  @teachings = load_teachings
  @menu_active = :teachings
  erb :'archive'
end

get '/teachings/:id/' do |id|
  File.open("data/teachings/#{id}.xml") do |file|
    @teachings = TeachingsDocument.new(Nokogiri::XML(file)).teachings
  end
  @teachings_slug = id
  @menu_active = :teachings
  erb :teachings
end

NewsStore = News.new("data/news")

get '/news' do
  @params = params
  NewsStore.load
  if params['top'] == 'true'
    @news = NewsStore.top(10)
  else
    @news = NewsStore.by_year(params['year'].to_i)
  end
  @years = NewsStore.years
  @menu_active = :news
  @extra_styles = @news.map { |n| n[:news].style }
  @extra_styles.compact!
  erb :'news-index'
end

get '/news/:id/' do |id|
  @news = NewsStore.find(id)
  @extra_styles = [ @news.style ]
  @extra_styles.compact!
  @slug = id
  @menu_active = :news
  erb :'news-single'
end

get '/book/:id/' do |id|
  File.open("data/book/#{id}/info.xml") do |file|
    @book = BookDocument.new(Nokogiri::XML(file)).book
  end
  @book_slug = id
  @categories = load_categories
  @menu_active = :library
  erb :book
end

get '/book-category/:id/' do |id|
  File.open("data/book-category/#{id}.xml") do |file|
    @category = BookCategoryDocument.new(Nokogiri::XML(file)).category
  end
  @books = {}
  @category.group.each do |group|
    group.book.each do |book|
      File.open("data/book/#{book}/info.xml") do |file|
        @books[book] = BookDocument.new(Nokogiri::XML(file)).book
      end
    end
  end
  @categories = load_categories
  @id = id
  @menu_active = :library
  erb :'book-category'
end

get '/library/' do
  @categories = load_categories
  @books = {}
  File.open('data/library.xml') do |file|
    @library = LibraryDocument.new(Nokogiri::XML(file)).library
  end
  @library.recent.book.each do |book_id|
    File.open("data/book/#{book_id}/info.xml") do |file|
      @books[book_id] = BookDocument.new(Nokogiri::XML(file)).book
    end
  end
  @menu_active = :library
  erb :library
end

get '/timetable' do
  File.open('data/timetable/timetable.xml') do |file|
    @timetable = TimetableDocument.new(Nokogiri::XML(file)).timetable
  end
  @menu_active = :timetable
  if params[:show] == 'week'
    erb :timetable
  elsif params[:show] == 'schedule'
    erb :classes
  end
end

get '/teachers/:teacher/' do |teacher|
  @teacher = teacher
  erb :teacher
end

get '/yoga/' do
  erb "<%= load_page('yoga/page.erb') %>"
end

get /\/(about|teachers|contacts|donations)\// do
  @menu_active = :about
  erb :center
end

get '/' do
  NewsStore.load
  @news = NewsStore.top(3)
  @extra_styles = @news.map { |n| n[:news].style }
  @extra_styles.compact!
  File.open('data/timetable/timetable.xml') do |file|
    @timetable = TimetableDocument.new(Nokogiri::XML(file)).timetable
  end
  File.open('data/quotes.xml') do |file|
    @quotes = QuotesDocument.new(Nokogiri::XML(file)).quotes
  end
  @teachings = load_teachings
  erb :index
end
