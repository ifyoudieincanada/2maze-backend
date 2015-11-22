require 'em-websocket'
require 'json'

games = {}
users = {}
game_counter = 0

def error(msg, ws)
  ws.send JSON.generate({ error: msg })
end

def send(name, args, ws)
  ws.send JSON.generate({ name: name, args: args })
end

def set_mode(id, data, ws, games, users, game_counter)
  return error('mode not set', ws) if data['mode'].blank?

  success = { message: 'mode set succesfully' }

  game = nil
  found = -1
  games.each do |key, val|
    if val['mode'] == data['mode']
      if val['p2'].nil?
        found = key
        game = val
        break;
      end
    end
  end
  if found == -1
    games[game_counter] = {
      'mode' => data['mode'],
      'p1'   => id,
      'p2'   => nil
    }
    users[id]['game-id'] = game_counter
    game_counter += 1
    send(:game_created, success, ws)
  else
    games[found]['p2'] = id
    users[id]['game-id'] = found
    send(:game_ready, success, ws)
    send(:game_ready, success, users[games[found]['p1']]['ws'])
  end
end

def stop_game(id, data, ws, games, users)
  game = games[users[id]['game-id']]

  users[game['p1']]['game-id'] = nil
  users[game['p2']]['game-id'] = nil

  close = { message: 'Game Over' }
  send(:disconnect, close, users[game['p1']]['ws'])
  send(:disconnect, close, users[game['p2']]['ws'])

  games.delete(users[id]['game-id'])
end

def coordinates(id, data, ws, games, users)
  return error('coordinates not valid') if data[:x].nil? || data[:y].nil?

  game = games[users[id]['game-id']]
  other_user_id = id == game['p1'] ? game['p2'] : game['p1']

  new_message = {
    message: {
      x: data['x'],
      y: data['y']
    }
  }
  send(:coordinates, new_message, users[other_user_id])
end

def game_finder(uid, games)
  games.each do |key, val|
    if val['p1'] == uid || val['p2'] == uid
      return key
    end
  end
  return -1
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
      users[id_counter] = {}
      users[id_counter]['ws'] = ws
      id_counter += 1
      puts "Created user ##{id_counter}"
      ws.send JSON.generate(response)
    }

    ws.onclose {
      # Find a way to delete the user and the user's potential game

      puts "Connection closed"
    }

    ws.onmessage { |msg|
      jmsg = JSON.parse(msg)

      case jmsg['path']
      when 'game.mode'
        set_mode(id, jmsg['data'], ws, games, users, game_counter)
      when 'game.stop'
        stop_game(id, jmsg['data'], ws, games, users)
      when 'game.coordinates'
        coordinates(id, jmsg['data'], ws, games, users)
      else
        error("Function #{jmsg['path']} not found", ws)
      end
    }
  end
}
