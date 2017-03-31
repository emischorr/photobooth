defmodule Photobooth.Camera do
  use GenServer
  require Logger

  @process_name :camera
  @update_time 1000
  @wait_time 30*1000
  @start_count 6
  @cycle_time 10*1000

  # states: waiting -> counting -> capturing -> showing

  # Client API

  def start_link() do
    GenServer.start_link(__MODULE__, {}, name: @process_name)
  end

  def start_countdown() do
    GenServer.call(@process_name, {:countdown})
  end

  def capture() do
    GenServer.call(@process_name, {:capture})
  end

  def show() do
    GenServer.call(@process_name, {:show})
  end

  def wait() do
    GenServer.call(@process_name, {:wait})
  end


  # Callbacks

  def init(_opts) do
    Process.flag(:trap_exit, true)
    Logger.info "Started Camera Server Process"
    {:ok, %{current_state: :waiting, count: @start_count, current_list: ["/images/capture.jpg"], current_slideshow_image: "/images/capture.jpg"}}
  end

  def handle_call({:countdown}, _from, state) do
    {:reply, :ok, start_countdown(state)}
  end

  def handle_call({:capture}, _from, state) do
    {:reply, :ok, capture(state)}
  end

  def handle_call({:show}, _from, state) do
    {:reply, :ok, show(state)}
  end

  def handle_call({:wait}, _from, state) do
    {:reply, :ok, wait(state)}
  end

  def handle_info(:count, state) do
    {:noreply, count(state)}
  end

  def handle_info(:capture, state) do
    {:noreply, capture(state)}
  end

  def handle_info(:wait, state) do
    {:noreply, wait(state)}
  end

  def handle_info(:cycle, state) do
    {:noreply, cycle(state)}
  end

  def handle_info(:show, state) do
    {:noreply, show(state)}
  end

  def handle_info({:EXIT, _port, _code}, state) do
    IO.puts "finished"
    {:noreply, state}
  end



  defp schedule_next_count do
    Process.send_after(self(), :count, @update_time)
  end

  defp schedule_capture do
    Process.send_after(self(), :capture, @update_time)
    # Process.send_after(self(), :wait, @wait_time)
  end

  defp start_countdown(state) do
    case state[:current_state] do
      :waiting ->
        IO.puts "[#{state[:current_state]} -> counting] started counting..."
        state |> put_in([:count], @start_count) |> put_in([:current_state], :counting) |> count
      :showing ->
        IO.puts "[#{state[:current_state]} -> counting] stopped showing. started counting..."
        state |> put_in([:count], @start_count) |> put_in([:current_state], :counting) |> count
      _ -> state
    end
  end

  defp count(state) do
    #TODO: only if current_state is counting
    IO.puts state[:count]-1
    case state[:count] do
      2 ->
        schedule_capture
        schedule_next_count
        update_in(state, [:count], &(&1-1)) |> broadcast
      x when x > 0 ->
        schedule_next_count
        update_in(state, [:count], &(&1-1)) |> broadcast
      _ ->
        Logger.info "Stopped countdown."
        state
    end
  end

  defp capture(state) do
    case state[:current_state] do
      :counting ->
        IO.puts "[#{state[:current_state]} -> capturing] capturing..."
        try do
          # gphoto2 --capture-image-and-download --keep-raw --force-overwrite --filename capture.jpg --hook-script priv/hook.sh
          System.cmd("gphoto2", [
            "--capture-image-and-download", "--keep", "--force-overwrite",
            "--filename=priv/static/images/capture.jpg",
            "--hook-script", "priv/hook.sh"
          ])
        rescue
          ErlangError -> IO.puts "Error accessing camera"
        end
        put_in(state, [:current_state], :capturing) |> broadcast |> capture
      _ -> state
    end
  end

  defp do_capture(state) do
    try do
      # gphoto2 --capture-image-and-download --keep-raw --force-overwrite --filename=priv/static/images/capture.jpg
      System.cmd("gphoto2", [
        "--capture-image-and-download", "--keep", "--force-overwrite",
        "--filename=priv/static/images/capture.jpg",
        "--hook-script", "priv/hook.sh"
      ])
    rescue
      ErlangError -> IO.puts "Error accessing camera"
    end
    Process.send_after(self(), :show, @update_time)
    state
  end

  defp show(state) do
    case state[:current_state] do
      :counting -> state
      _ ->
        IO.puts "[#{state[:current_state]} -> showing] show image"
        Process.send_after(self(), :wait, @wait_time)
        put_in(state, [:current_state], :showing) |> broadcast
    end
  end

  defp wait(state) do
    case state[:current_state] do
      :waiting -> state
      :capturing -> state
      :counting -> state
      _ ->
        IO.puts "[#{state[:current_state]} -> waiting] going to wait..."
        Process.send_after(self(), :cycle, @cycle_time)
        put_in(state, [:current_state], :waiting)
        |> refresh_file_list
        |> next_slideshow
        |> broadcast
    end
  end

  defp cycle(state) do
    case state[:current_state] do
      :waiting ->
        Process.send_after(self(), :cycle, @cycle_time)
        state |> next_slideshow |> broadcast
      _ -> state
    end
  end

  defp broadcast(state) do
    Photobooth.Endpoint.broadcast "photobooth", "state:update", state
    state
  end

  defp next_slideshow(state) do
    # calculate index of new image
    new_index = Enum.find_index(state[:current_list], &(&1 == state[:current_slideshow_image]))
    |> next_index
    |> rem(Enum.count(state[:current_list]))
    # set current_slideshow_image in state
    put_in(state, [:current_slideshow_image], Enum.at(state[:current_list], new_index))
  end

  defp next_index(index) do
    case index do
      old when is_number(old) -> old+1
      _ -> 0
    end
  end

  defp refresh_file_list(state) do
    {:ok, list} = File.ls("priv/static/images/slideshow")
    files = list
    |> Enum.filter(fn(f) -> String.ends_with?(f, ".jpg") end)
    |> Enum.sort(&(&1 >= &2))
    put_in(state, [:current_list], files)
  end

end
