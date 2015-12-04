require 'two_maze/web_socket_manager'
require 'two_maze/web_socket'
require 'two_maze/game'

module TwoMaze
  def TwoMaze.manager
    WebSocketManager.new
  end
end
