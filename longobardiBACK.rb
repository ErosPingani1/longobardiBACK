require 'sinatra'
require 'fcm'
require 'digest'
require 'json'
require 'active_support/json'

KEY = '196B5815CDE73CAE5CD7018359B851BBA754F80BB36FB7D50C1650F012496F70'

#Firebase Cloud Messaging Server Key
$fcm = FCM.new('AAAA0ID3FSw:APA91bHveLJLI9jU_M3GQAN1ej-H8DjOFtxbFwGJ9kqWD2Ct8m1KoMc9FoTS9QAeQo62nj_PJ6jmkEvlGH0nmPqSIwpo7bZaEN0tXNUWCXakM-D6G9UGhphAmB8KVAFd1AmO-09WeI2E')
#longobardicAPP registration token taken at opening from AStudio console (emulator, Pixel 3a)
$registration_ids = ['e07mwn9JTCqIhKCkDFOr9g:APA91bEAwliA2uFbIP9pOFh8XlZ96R6S_jyQL1SapZK3SaxOhgQ6r2WGfuRoFRQRZhAmGbBdikc5vYChWwtpeMd9hIYCb3VsIjQxAYXsq1CLpUM-08eeHEsCX_lRNn_wVRe47F2shjJe', 'fOhLXUDkT9q5Sy_zA334I3:APA91bFfS8arvQgx4Po0DPIx26_ayYE_q8_4y37LLrj88-VgrFFIEce9fHmUNMozhSnSACWrE7sWvqCsWtMeRprKlfSLOQaWHgHht4UJ6BLV-L-YKkuXFw-PeANifxXB_CbFd8Cz3cBY']

def checkHashKey(hashkey, date, time, battery)
    return (Digest::SHA1.hexdigest KEY + date + time + battery).downcase == hashkey.downcase ? true : false
end

def sendPushNotification(newMail) 
    options = {
        "priority": "high",
        "notification": {
            "title": "De pusc notifichescio",
            "body": "Va che bella notifica che ti ho preso"
        },
        "data": {
            "mail": newMail
        }
    }
    response = $fcm.send($registration_ids, options)
    puts('Service response: ', response)
end

class Mail
    attr_accessor :date, :time, :battery, :description
end

class LongobardiBACK < Sinatra::Base
    mail = Mail.new()
    #Called by ESP8266 when the sensor is triggered
    post '/newMail' do
        response = {}
        hashkey = params['hashkey']
        date = params['date']
        time = params['time']
        battery = params['battery']
        if (checkHashKey(hashkey, date, time, battery)) #The hashkey is checked to avoid data manipulation from unknown sources
            mail.date = date
            mail.time = time
            mail.battery = battery
            response['status'] = 'ok'
            response['message'] = 'New mail registered'
            response['mail'] = JSON.parse(ActiveSupport::JSON.encode(mail))
            sendPushNotification(response)
        else
            response['status'] = 'ko'
            response['message'] = 'An error occured, please try again'
        end
        content_type :json
        response.to_json
    end
end