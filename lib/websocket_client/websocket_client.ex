defmodule WebsocketClient.Server do
  @moduledoc """
  GenServer which handles a websocket connection. It restarts if it shuts down.

  This is a demonstration of how to use gun with an GenServer wrapper in Elixir
  """

  require Logger

  @me ClientServer

  # Here's what I want to put in state
  # In most real life cases you'll want to pass these in
  defstruct path: "/",
            port: 80,
            # Note the single quotes. This only works with single quotes so bear that in mind it
            # needs to be a charlist or gun will give back errors.
            host: 'echo.websocket.org',
            # These will be set after gun connects
            stream_ref: nil,
            gun_pid: nil,
            # Optionally set this if you want to control this client from elsewhere
            # Use :set_from
            from: nil

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, opts},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def init(:no_args) do
    Logger.info "Websocket client started..."

    # Set initial state as default values and return from `init`
    {:ok, %__MODULE__{ }}
  end

  def start_link do
    GenServer.start_link(__MODULE__, :no_args, name: @me)
  end

  @doc """
  This supports sending any of the handle_call functions which are accessed from WebsocketClient.Application
  """
  def send_sync(args_tuple) do
    Logger.info inspect args_tuple
    GenServer.call(@me, args_tuple)
  end

  @doc """
  This supports sending any of the handle_cast functions which are accessed from WebsocketClient.Application
  """
  def send_async(args_tuple) do
    GenServer.cast(@me, args_tuple)
  end

  @doc """
  This sends back the current state of this server
  """
  def handle_call({:get_state}, _from, state) do
    {:reply, state, state}
  end

  @doc """
  This opens the websocket which includes
  get > upgrade > success
  This sets the relevant values in state
  This is blocking so the client can't send until the websocket is open

  This also sets from so you can send the results back to the calling process
  """
  def handle_call({:open_ws}, _from, state) do
    {:reply, :ok, ws_upgrade(state) }
  end

  @doc """
  If you want to set the calling process of this server you can do it here
  """
  def handle_cast({:set_from, from}, state) do
    {:noreply, %__MODULE__{state | from: from}}
  end

  @doc """
  This sends a message after the websocket connection has been opened
  """
  def handle_cast({:send_message, message}, %{gun_pid: gun_pid} = state) do
    case :gun.ws_send(gun_pid, {:text, message}) do
      :ok ->
        {:noreply, state}
      reply ->
        Logger.info("Error on sending message from gun. Maybe the websocket is not open... #{inspect reply}")
        {:noreply, state}
    end
  end


  ####
  # gun upgrade functions
  ####

  @doc """
  This is the one it hits if upgrade is successful and from is nil (not set)
  """
  def handle_info({:gun_upgrade, gun_pid, stream_ref, ["websocket"], headers},
    %{stream_ref: stream_ref, gun_pid: gun_pid, from: nil} = state
    ) do
    Logger.info("Upgraded #{inspect(gun_pid)}. Success!\nHeaders:\n#{inspect(headers)}")
    {:noreply, state}
  end

  @doc """
  This is the one it hits if upgrade is successful and from is set
  This sends a message back to the calling function that the websocket is open and can send and receive messages
  """
  def handle_info({:gun_upgrade, gun_pid, stream_ref, ["websocket"], headers},
    %{stream_ref: stream_ref, gun_pid: gun_pid, from: from} = state
    ) do
    Logger.info("Upgraded #{inspect(gun_pid)}. Success!\nHeaders:\n#{inspect(headers)}")
    # Give from process a message that the websocket is now open.
    GenServer.reply(from, {:websocket_open})
    {:noreply, state}
  end

  @doc """
  Upgrade not successful
  """
  def handle_info({:gun_response, _gun_pid, _, _, status, headers}) do
    Logger.info "Websocket upgrade failed."
    exit({:ws_upgrade_failed, status, headers})
  end

  @doc """
  Error on upgrade
  """
  def handle_info({:gun_error, _gun_pid, _stream_ref, reason}) do
    exit({:ws_upgrade_failed, reason})
  end

  ####
  # End of upgrade functions
  ####


  ####
  # gun messages
  ####

  @doc """
  Receiving message with no 'from' process
  """
  def handle_info({:gun_ws, gun_pid, stream_ref, {:text, message}}, %{stream_ref: stream_ref, gun_pid: gun_pid, from: nil} = state) do
    Logger.info("Message received #{inspect message}")
    {:noreply, state}
  end

  @doc """
  Gun receives a message from the backend and we return it to the calling process.
  """
  def handle_info({:gun_ws, gun_pid, stream_ref, {:text, message}}, %{stream_ref: stream_ref, gun_pid: gun_pid, from: from} = state) do
    # Give it back to the calling process
    # If you're using another GenServer you should probably use GenServer.reply/2
    send(from, %{message: message})
    {:noreply, state}
  end

  @doc """
  If the gun_pid matches, restart? - currently restarting on below call
  """
  def handle_info({:gun_down, gun_pid, _http_ws, :closed, [], []}, %{gun_pid: gun_pid} = state) do
    # Toggle this to restart here
    # {:noreply, ws_upgrade(state) }
    {:noreply, state}
  end

  @doc """
  If the gun_pid doesn't match, don't restart, it's probably obsolete.
  """
  def handle_info({:gun_down, _alt_gun_pid, _http_ws, :closed, [], []}, %{gun_pid: _gun_pid} = state) do
    {:noreply, state}
  end

  @doc """
  This is instructing gun to close, so we restart
  This could be more granular by matching on the code which is currently ignored.
  """
  def handle_info({:gun_ws, gun_pid, stream_ref, {:close, _code, ""}}, %{stream_ref: stream_ref, gun_pid: gun_pid} = state) do
    # Re-open the websocket connection if it closes here.
    {:noreply, ws_upgrade(state) }
  end

  @doc """
  Handle gun_up - this can be monitored if desired.
  http_ws is :http or :ws
  """
  def handle_info({:gun_up, gun_pid, _http_ws}, %{gun_pid: gun_pid} = state) do
    {:noreply, state}
  end

  @doc """
  Handle gun_up - this can be monitored if desired.
  http_ws is :http or :ws
  """
  def handle_info({:gun_up, _alt_gun_pid, _http_ws}, %{gun_pid: _gun_pid} = state) do
    {:noreply, state}
  end

  @doc """
  If this hits, something unexpected happened. Perhaps an error.
  This is meant to be a catch all for all other messages.
  """
  def handle_info(message, state) do
    Logger.error "Unexpected message: #{inspect message, pretty: true} with state: #{inspect state, pretty: true}"
    {:noreply, state}
  end

  @doc """
  This gets the websocket to the state of upgrade where the upgrade message
  needs to be received in one of the handle_info functions
  """
  def ws_upgrade(state) do

    %{ path: path, port: port, host: host } = state

    {:ok, _} = :application.ensure_all_started(:gun)
    connect_opts = %{
      connect_timeout: :timer.minutes(1),
      retry: 10,
      retry_timeout: 300
    }

    {:ok, gun_pid} = :gun.open(host, port, connect_opts)
    {:ok, _protocol} = :gun.await_up(gun_pid)
    # Set custom header with cookie for device id
    stream_ref = :gun.ws_upgrade(gun_pid, path)
    # Return updated state
    %__MODULE__{state | stream_ref: stream_ref, gun_pid: gun_pid}
  end

end
