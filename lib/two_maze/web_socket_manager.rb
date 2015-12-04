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
      @users.delete websocket.id
    end

    def add_to_game(websocket)
      if @games[:open][websocket.level].empty?
        game = Game.new(websocket, websocket.level)

        websocket.in_game(game)

        @games[:open][websocket.level][game.id] = game
      else
        begin
          game = games[:open][websocket.level].first
          @games[:open][websocket.level].delete game.id

          websocket.in_game(game)

          @games[:full][websocket.level][game.id] = game
        rescue
          game = Game.new(websocket, websocket.level)

          websocket.in_game(game)

          @games[:open][websocket.level][game.id] = game
        end
      end
    end

    def remove_from_game(websocket)
      if websocket.game.started?
        @games[:full][websocket.level].delete websocket.game.id
      else
        @games[:open][websocket.level].delete websocket.game.id
      end

      websocket.game_over!
    end
  end
end
