require 'json'

module TwoMaze
  class TwoMaze::WebSocketManager
    def initialize
      @games = {
        open: {
          easy: {},
          medium: {},
          hard: {}
        },
        full: {
          easy: {},
          medium: {},
          hard: {}
        }
      }
      @users = {}
    end

    def socket(ws)
      WebSocket.new(ws, self)
    end

    def add(websocket)
      @users[websocket.id] = websocket
    end

    def remove(websocket)
      @users.delete(websocket.id)
    end

    def add_to_game(websocket)
      puts 'Adding user to game'
      if @games[:open][websocket.level].empty?
        puts "@games[:open][#{websocket.level}] is empty"
        game = Game.new(websocket, websocket.level)

        websocket.in_game(game)

        @games[:open][websocket.level][game.id] = game
      else
        begin
          puts "@games[:open][#{websocket.level}] is not empty"
          id, game = @games[:open][websocket.level].first
          @games[:open][websocket.level].delete(id)

          websocket.in_game(game)

          @games[:full][websocket.level][id] = game
          @games[:full][websocket.level][id].add(websocket)

          puts 'game put in :full'
        rescue
          puts 'Rescuing'
          game = Game.new(websocket, websocket.level)

          websocket.in_game(game)

          @games[:open][websocket.level][game.id] = game
        end
      end
    end

    def remove_from_game(websocket)
      puts 'Ending game'
      websocket.game_over!

      if websocket.game.started?
        @games[:full][websocket.level].delete websocket.game.id
      else
        @games[:open][websocket.level].delete websocket.game.id
      end
      puts 'Game ended'
    end
  end
end
