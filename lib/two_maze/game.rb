module TwoMaze
  class TwoMaze::Game
    def Game.counter
      @counter ||= 0
      @counter += 1
      @counter
    end

    def initialize(websocket, level)
      @game_id = Game.counter
      @level = level
      @websockets = {
        p1: websocket
      }
      websocket.player(1)

      @ready = false
      preapre_maze
      @active = false

      send(1, :game_created, { message: "game with mode #{@level} created" })
    end

    def id
      @game_id
    end

    def start!
      @active = true
    end

    def started?
      @active
    end

    def stop!
      send(0, :disconnect, { message: 'Game Over' })
      @websockets[:p1].clear_game!
      unless @websockets[:p2].nil?
        @websockets[:p2].clear_game!
      end
      @websockets[:p1] = nil
      @websockets[:p2] = nil
      @active = false
    end

    def send(id, name, data)
      if id == 1
        @websockets[:p1].send(name, data)
      elsif id == 2
        @websockets[:p2].send(name, data)
      elsif id == 0 # send to both
        @websockets[:p1].send(name, data)
        @websockets[:p2].send(name, data)
      else
        # not a valid id
      end
    end

    def add(websocket)
      if @websockets[:p2].nil?
        websocket.player(2)
        @websockets[:p2] = websocket

        if @ready
          send(1, :game_ready, { message: { maze: @maze, player: 1 } })
          send(2, :game_ready, { message: { maze: @maze, player: 2 } })
        end
      else
        # throw an error because the game is already full
      end
    end

    def remove(websocket) # shouldn't be used
      if websocket.player == 1
        @websockets.delete :p1
      elsif websocket.player == 2
        @websockets.delete :p2
      else
        # user not in game
      end
    end

    private

    def prepare_maze
      mazes = Dir.entries('maps')
      # change what map it reads based on @level
      mazes.select! { |maze| maze.start_with? '16_' }

      @maze = []
      File.open(File.join('maps', mazes.sample)).each_with_index do |line, index|
        @maze.push([])
        line.each_char { |x| maze[index].push(x) }
      end

      @ready = true
    end
  end
end
