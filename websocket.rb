require 'em-websocket'
require 'json'

games = {}
users = {}

def error(msg)
  ws.send JSON.generate({ error: msg })
end

def ping(id, data)
  puts "Recieved message: #{data}"
  data['text'] = "Pong: #{data['text']}"
  ws.send JSON.generate(data)
end

def set_mode(id, data)
  return error('mode not set') if data['mode'].blank?

  success = { message: 'mode set succesfully' }

  game = nil
  found = 0
  games.each do |key, val|
    if val['mode'] == data['mode']
      if val['p2'].nil?
        found = key
        game = val
        break;
      end
    end
  end
  games[found]['p2'] = id

  ws.send JSON.generate() ## FIX THIS SOON, FINISH FUNCTION SOON, IDK
end

def stop_game(id, data)
end

def coordinates(id, data)
end

id_counter = 0

EM.run {
  EM::WebSocket.run(host: "localhost", port: 8080) do |ws|
    ws.onopen { |handshake|
      puts "WebSocket connection open"

      # Access properties on the EM::WebSocket::Handshake object, e.g.
      # path, query_string, origin, headers

      # Publish message to the client
      response = {
        status: 'connected',
        id: id_counter
      }
      id_counter += 1
      ws.send JSON.generate(response)
    }

    ws.onclose {
      puts "Connection closed"
    }

    ws.onmessage { |msg|
      jmsg = JSON.parse(msg)

      case jmsg['path']
      when 'game.ping'
        ping(id, jmsg['data'])
      when 'game.mode'
        set_mode(id, jmsg['data'])
      when 'game.stop'
        stop_game(id, jmsg['data'])
      when 'game.coordinates'
        coordinates(id, jmsg['data'])
      else
        ws.send JSON.generate({ error: "Function #{jmsg['path']} not found" })
      end
    }
  end
}
