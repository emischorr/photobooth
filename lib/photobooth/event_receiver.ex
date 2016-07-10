defmodule Photobooth.EventReceiver do
  use GenServer
  require Logger
  alias Photobooth.Camera

  @process_name :event_receiver
  @redis_sub_channel "photobooth.event"

  def start_link do
    GenServer.start_link(__MODULE__, [], name: @process_name)
  end

  def init(_opts) do
    {:ok, %{pub_sub_con: nil}, 0}
  end

  def handle_info(:timeout, _state) do
    # timeout of 0 on init on purpose to defer the redis queue subscribe to here
    {:ok, pub_sub_conn} = Redix.PubSub.start_link
    :ok = Redix.PubSub.psubscribe(pub_sub_conn, @redis_sub_channel, self())

    {:noreply, %{pub_sub_conn: pub_sub_conn}}
  end

  def handle_info({:redix_pubsub, _pid, :psubscribed, _data}, state) do
    {:noreply, state}
  end

  def handle_info({:redix_pubsub, _pid, :pmessage, data}, state) do
    "photobooth."<>event = data[:channel]
    #IO.puts "Handling Event <#{event}>: #{inspect data}"
    case data[:payload] do
      "countdown" -> Camera.start_countdown()
      "capture" -> Camera.capture()
      "show" -> Camera.show()
      x -> Logger.warn "Unknown event: #{x}"
    end

    {:noreply, state}
  end

end
