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
  return error('mode not set', ws) if data['mode'].nil?

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

    mazes = Dir.entries('maps')
    mazes.select! { |maze| maze.start_with? '64_' }

    maze = []
    File.open(File.join('maps', mazes.sample)).each_with_index do |line, index|
      maze.push([])
      line.each_char { |x| maze[index].push(x) }
    end

    unless maze.nil?
      send(:game_ready, success.merge({ message: { maze: maze, player: 1 } }), ws)
      send(:game_ready, success.merge({ message: { maze: maze, player: 2 } }), users[games[found]['p1']]['ws'])
    end
  end
end

def save_maze(id, data, ws, games, users)
  # return error('maze not set', ws) if data['maze'].nil?

  # success = { message: 'maze saved' }

  # mazes = Dir.entries('maps')
  # mazes.select! { |maze| maze.startwith? '64_' }

  # maze = []
  # file.open(mazes.sample).each_with_index do |line, index|
  #   maze.push([])
  #   line.each_char { |x| maze[index] = x }
  # end

  # games[users[id]['game-id']]['maze'] = maze
  send(:maze_saved, success, ws)
end

def stop_game(id, data, ws, games, users)
  game = games[users[id]['game-id']]

  begin # this may be called by both clients, but should only work once
    users[game['p1']]['game-id'] = nil
    users[game['p2']]['game-id'] = nil

    close = { message: 'Game Over' }
    send(:disconnect, close, users[game['p1']]['ws'])
    send(:disconnect, close, users[game['p2']]['ws'])

    games.delete(users[id]['game-id'])
  rescue
  end
end

def coordinates(id, data, ws, games, users)
  return error('coordinates not valid', ws) if data["x"].nil? || data["y"].nil?

  game = games[users[id]['game-id']]
  other_user_id = id == game['p1'] ? game['p2'] : game['p1']

  new_message = {
    message: {
      x: data['x'],
      y: data['y']
    }
  }
  send(:coordinates, new_message, users[other_user_id]['ws'])
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
      id = jmsg['id']

      case jmsg['path']
      when 'game.mode'
        set_mode(id, jmsg['data'], ws, games, users, game_counter)
      when 'game.stop'
        stop_game(id, jmsg['data'], ws, games, users)
      when 'game.coordinates'
        coordinates(id, jmsg['data'], ws, games, users)
      when 'game.maze'
        save_maze(id, jmsg['data'], ws, games, users)
      else
        error("Function #{jmsg['path']} not found", ws)
      end
    }
  end
}
