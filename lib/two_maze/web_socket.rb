require 'json'

module TwoMaze
  class TwoMaze::WebSocket

    def WebSocket.id_counter
      @count ||= 0
      @count += 1
      @count
    end

    def initialize(ws, manager)
      puts 'Creating Websocket User'
      @websocket = ws
      @manager = manager
      @player = nil

      onopen
      onmessage
      onerror
      onclose
      puts 'User Created'
    end

    def id
      @user_id
    end

    def set_level(level)
      @level = level.to_sym
    end

    def level
      @level
    end

    def set_player(player) # should be 1 or 0
      @player = player
    end

    def player
      @player
    end

    def game
      @game
    end

    def in_game(game)
      @game = game
    end

    def in_game?
      return @game != nil
    end

    def clear_game!
      @game = nil
    end

    def game_over!
      @game.stop! if in_game?
    end

    def send_error(msg)
      @websocket.send JSON.generate({ error: msg })
    end

    def send(name, args)
      @websocket.send JSON.generate({ name: name, args: args })
    end

    private

    def onopen
      @websocket.onopen { |handshake|
        puts 'Opening connection'
        @user_id = WebSocket.id_counter
        @manager.add(self)
        @websocket.send JSON.generate({ status: 'connected', id: @user_id })
        puts 'Connection opened'
      }
    end

    def onmessage
      @websocket.onmessage { |msg|
        puts 'Got message'
        jmsg = JSON.parse(msg)

        case jmsg['path']
        when 'game.mode'
          set_level(jmsg['data']['mode'])
          unless @level.nil?
            @manager.add_to_game(self)
          end
        when 'game.stop'
          game_over!
        when 'game.coordinates'
          coordinates = {
            message: {
              x: jmsg['data']['x'],
              y: jmsg['data']['y']
            }
          }
          # 3 - player is either 1 or 2
          @game.send(3 - player, :coordinates, coordinates)
        else
          send_error("Function #{jmsg['path']} not found")
        end
        puts 'Message handled'
      }
    end

    def onerror
      @websocket.onerror { |reason|
        puts 'Got error'
        if defined? reason
          puts reason
          send_error(reason)
        end
        puts 'Error handled'
      }
    end

    def onclose
      @websocket.onclose { |reason|
        puts 'Closing connection'
        game_over! if in_game?
        puts reason if defined? reason
        @manager.remove(self)
        puts 'Connection closed'
      }
    end
  end
end
