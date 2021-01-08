require 'sinatra'
require 'json'

class Mail
    attr_accessor :date, :time, :battery, :description
end

class LongobardiBACK < Sinatra::Base
    newMail = false
    mail = Mail.new()
    puts('First run, available inboxes? ', newMail)
    post '/newMail' do
        newMail = true
        mail.date = params['date']
        mail.time = params['time']
        mail.battery = params['battery']
        puts('Hey, there\'s a new Inbox!')
        # Aggiungere gestione response
    end
    get '/checkMailbox' do
        response = {}
        if (newMail) 
            response['available'] = true
            response['mail'] = mail
            newMail = false
        else 
            response['available'] = false
        end
        content_type :json
        response.to_json
    end
end