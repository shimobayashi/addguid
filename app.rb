require 'sinatra'

class AddGuid < Sinatra::Base
  enable :show_exceptions

  get '/' do
    'hello'
  end
end
