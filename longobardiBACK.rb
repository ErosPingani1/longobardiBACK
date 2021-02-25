require 'sinatra'
require 'fcm'
require 'digest'
require 'json'
require 'active_support/json'

KEY = '196B5815CDE73CAE5CD7018359B851BBA754F80BB36FB7D50C1650F012496F70'

#Firebase Cloud Messaging Server Key
$fcm = FCM.new('AAAA0ID3FSw:APA91bHveLJLI9jU_M3GQAN1ej-H8DjOFtxbFwGJ9kqWD2Ct8m1KoMc9FoTS9QAeQo62nj_PJ6jmkEvlGH0nmPqSIwpo7bZaEN0tXNUWCXakM-D6G9UGhphAmB8KVAFd1AmO-09WeI2E')
#longobardicAPP registration token taken at opening from AStudio console (emulator, Pixel 3a)
$registration_ids = ['fj0OMkIhTgSgayKFCORl0Q:APA91bFKezxVnxeR_8xo2s0aP52hSVjNl5FS9-h5oH_t5L0X3BI8qH46xyWxUo5v3ULnUysRsiSxHDnxbpxdUVOVXEsCzIj7gzIXaNyOT75_d3lTIbShG6tlpvcDjDy0pcAO_n0Z6wNs', 'dgQXDnRXQUqF9P6f58Kj8B:APA91bH349vcDmBx4njTYqjo8GXcisCcz1WbYfQmUfU1vsubut--eN0gSAszTX_eTo_UFg5WAurHIRv0BVfrzY3u696Y8DV9JdctPZaUOX4hRSV93kbDtMBkC4JYrZ2n2YCS8Pk6wPpS']

#ArduinoInfo class that contains information about the device that called the service
#Every call to the service has to pass these params (date, time, battery)
class ArduinoInfo
    attr_accessor :date, :time, :battery, :location, :device
end

def setArduinoInfo(arduinoInfo, params)
    arduinoInfo.date = params['date']
    arduinoInfo.time = params['time']
    arduinoInfo.battery = params['battery']
    arduinoInfo.location = params['location'] == 'fara' ? 'Fara Gera d\'Adda' : 'Location'
    arduinoInfo.device = params['device'] == 'nodemcu' ? 'NodeMCU esp8266' : 'Device'
end

def checkHashKey(hashkey, date, time, battery)
    return (Digest::SHA1.hexdigest KEY + date + time + battery).downcase == hashkey.downcase ? true : false
end

def sendPushNotification(notificationData) 
    options = {
        "priority": "high",
        "notification": {
            "title": "New mail",
            "body": "There's something new in your mailbox, check it out!"
        },
        "data": {
            "content": notificationData
        }
    }
    pushResponse = $fcm.send($registration_ids, options)
    puts('Service response: ', pushResponse)
end

class LongobardiBACK < Sinatra::Application
    configure do
        set :port, 9292
        set :bind, '0.0.0.0'
    end
    arduinoInfo = ArduinoInfo.new()
    mailbox_recording = true
    #Called by ESP8266 when the sensor is triggered
    post '/newMail' do
        response = {}
        hashkey = params['hashkey']
        setArduinoInfo(arduinoInfo, params)
        if (checkHashKey(hashkey, arduinoInfo.date, arduinoInfo.time, arduinoInfo.battery)) #The hashkey is checked to avoid data manipulation from unknown sources
            response['status'] = 'ok'
            response['message'] = 'New mail registered'
            response['arduinoInfo'] = JSON.parse(ActiveSupport::JSON.encode(arduinoInfo))
            response['notificationType'] = 1
            sendPushNotification(response)
        else
            response['status'] = 'ko'
            response['message'] = 'An error occured, please try again'
        end
        content_type :json
        response.to_json
    end
    #Automatically triggered by Arduino every minute to update device status
    post '/setStatus' do
        response = {}
        hashkey = params['hashkey']
        setArduinoInfo(arduinoInfo, params)
        if (checkHashKey(hashkey, arduinoInfo.date, arduinoInfo.time, arduinoInfo.battery))
            response['status'] = 'ok'
            response['message'] = 'Device info updated'
        else
            response['status'] = 'ko'
            response['message'] = 'An error occured, please try again'
        end
        content_type :json
        response.to_json
    end
    #Service called at app opening to get the current ESP8266 status to show on mailbox detail page
    get '/getStatus' do
        response = {}
        hashkey = params['hashkey']
        dTb = [params['date'], params['time'], params['battery']]
        if (checkHashKey(hashkey, dTb[0], dTb[1], dTb[2]))
            response['status'] = 'ok'
            response['message'] = 'Device info correctly delivered to client'
            response['mailboxStatus'] = { device: arduinoInfo.device, location: arduinoInfo.location, battery: arduinoInfo.battery, recording: mailbox_recording }
        else
            response['status'] = 'ko'
            response['message'] = 'An error occured, please try again'
        end
        content_type :json
        response.to_json
    end
    run! if $0 == app_file
end