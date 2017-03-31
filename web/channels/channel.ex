defmodule Photobooth.Channel do
  use Phoenix.Channel
  require Logger

  alias Photobooth.Camera

  def join("photobooth", message, socket) do
    Process.flag(:trap_exit, true)

    {:ok, socket}
  end

  def handle_in("photobooth:start", _msg, socket) do
    Camera.start_countdown()
    {:noreply, socket}
  end

  def terminate(reason, socket) do
    Logger.debug"> socket closed: #{inspect reason}"
    :ok
  end

  def handle_in("reset", msg, socket) do
    Logger.debug"> reset: #{inspect msg}"
    # TODO

    {:noreply, socket}
  end
end
