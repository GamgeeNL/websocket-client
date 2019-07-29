defmodule WebsocketClient.Application do
  use Application

  require Logger

  def start(_type, _args) do

    # Define workers and child supervisors to be supervised
    children = [
      { WebsocketClient.Server, [] }
    ]

    opts = [strategy: :one_for_one, name: WebsocketClient.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  This opens a websocket
  """
  def open_ws do
    Logger.info "Open ws yo"
    WebsocketClient.Server.send_sync({:open_ws})
  end

  @doc """
  This gets the state
  """
  def get_state do
    Logger.info(inspect(WebsocketClient.Server.send_sync({:get_state}), pretty: true))
  end

  @doc """
  This sends a message to the the websocket through the client
  """
  def send_message(message) do
    WebsocketClient.Server.send_async({:send_message, message})
  end

  @doc """
  This allows you to use another process to remote control this one
  """
  def set_from do
    WebsocketClient.Server.send_async({:set_from, self()})
    message = "I love you"
    Logger.info "Sending... #{inspect message}"
    WebsocketClient.Server.send_async({:send_message, message})

    receive do
      %{message: "I love you"} ->
         Logger.info "I love you more!"

      message ->
        Logger.info "Now receiving in Application... #{inspect message}"
    end

  end

end
