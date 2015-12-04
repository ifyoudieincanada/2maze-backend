require 'json'

module TwoMaze
  class TwoMaze::WebSocket

    def WebSocket.id_counter
      @count ||= 0
      @count += 1
      @count
    end

    def initialize(ws, manager)
      @websocket = ws
      @manager = manager
      @player = nil

      onopen
      onmessage
      onerror
      onclose
    end

    def id
      @user_id
    end

    def level(level)
      @level = level.to_sym
    end

    def level
      @level
    end

    def player(player) # should be 1 or 0
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
      @game.stop!
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
        @user_id = WebSocket.id_counter
        @manager.add(self)
        @websocket.send JSON.generate({ status: 'connected', id: @user_id })
      }
    end

    def onmessage
      @websocket.onmessage { |msg|
        jmsg = JSON.parse(msg)

        case jmsg['path']
        when 'game.mode'
          @level = jmsg['data']['mode']
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
      }
    end

    def onerror
      @websocket.onerror { |reason|
        if defined? reason
          puts reason
          send_error(reason)
        end
      }
    end

    def onclose
      @websocket.onclose { |reason|
        game_over! if in_game?
        puts reason if defined? reason
        @manager.remove(self)
      }
    end
  end
end
