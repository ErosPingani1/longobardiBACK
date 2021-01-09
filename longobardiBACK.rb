require 'sinatra'
require 'digest'
require 'json'
require 'active_support/json'

KEY = '196B5815CDE73CAE5CD7018359B851BBA754F80BB36FB7D50C1650F012496F70'

def checkHashKey(hashkey, date, time, battery)
    return (Digest::SHA256.hexdigest KEY + date + time + battery).downcase == hashkey.downcase ? true : false
end

class Mail
    attr_accessor :date, :time, :battery, :description
end

class LongobardiBACK < Sinatra::Base
    newMail = false
    mail = Mail.new()
    #Called by ESP8266 when the sensor is triggered
    post '/newMail' do
        response = {}
        hashkey = params['hashkey']
        date = params['date']
        time = params['time']
        battery = params['battery']
        if (checkHashKey(hashkey, date, time, battery)) #The hashkey is checked to avoid data manipulation from unknown sources
            newMail = true
            mail.date = date
            mail.time = time
            mail.battery = battery
            response['status'] = 'ok'
            response['message'] = 'New mail registered'
        else
            response['status'] = 'ko'
            response['message'] = 'An error occured, please try again'
        end
        content_type :json
        response.to_json
    end
    #Called by longobardicAPP to check whether a new mail is available
    get '/checkMailbox' do
        response = {}
        if (newMail) 
            response['status'] = 'ok'
            response['available_inbox'] = true
            response['mail'] = JSON.parse(ActiveSupport::JSON.encode(mail)) #Hashed object converted in JSON
            newMail = false
        else 
            response['status'] = 'ko'
            response['available_inbox'] = false
        end
        content_type :json
        response.to_json
    end
end