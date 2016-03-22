#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'two_maze'
require 'em-websocket'

manager = TwoMaze.manager

EM.run {
  EM::WebSocket.run(host: "0.0.0.0", port: 8080) do |ws|
    manager.socket(ws)
  end
}
