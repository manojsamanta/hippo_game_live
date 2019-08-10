defmodule HippoGameLiveWeb.HippoGameLive do
  use Phoenix.LiveView

  @game_time 20
  @track_length 10

  @stored_text ["seattle", "portland", "bangkok", "tokyo", "london", "moscow", "vancouver"]

  def render(assigns) do
    HippoGameLiveWeb.HippoGameView.render("index.html", assigns)
  end

  def mount(session, socket) do
    socket =
      socket
      |> new_game()

    if connected?(socket) do
      {:ok, schedule_tick(socket)}
    else
      {:ok, socket}
    end
  end

  defp new_game(socket) do
    assign(socket,
      track: map(),
      player_x: 1,
      start_time: System.os_time(:second),
      gameplay?: true,
      time_left: @game_time,
      text_to_type: @stored_text |> Enum.shuffle |> Enum.at(0),
      extra_letters: 0
    )
  end

  defp schedule_tick(socket) do
    Process.send_after(self(), :tick, 1000)
    socket
  end

  def handle_info(:tick, socket) do
    timeleft = socket.assigns.start_time + @game_time - System.os_time(:second)

    if timeleft <= 0 do
      {:noreply, assign(socket, gameplay?: false, time_left: 0,)}
    else
      new_socket = schedule_tick(socket)
      {:noreply, assign(new_socket, time_left: timeleft)}
    end
  end

  def handle_event("player", key, socket) when key in ["=", "+"] do
    if socket.assigns.gameplay? do
      {:noreply, socket}
    else
      {:noreply, schedule_tick(new_game(socket))}
    end
  end

  def handle_event("player", key, socket) do
    if socket.assigns.gameplay? do
      {:noreply, step(socket, key)}
    else
      {:noreply, socket}
    end
  end

  defp map() do
    for x <- 1..@track_length, into: %{} do
      {x, :empty}
    end
  end

  defp step(socket, key) do
    old_position = socket.assigns.player_x
    text_to_type=socket.assigns.text_to_type
    extra_letters=socket.assigns.extra_letters

    {x, text_left, extra_letters} = get_new_position(socket, text_to_type, key, extra_letters)
    assign(socket, player_x: x, text_to_type: text_left, extra_letters: extra_letters)
  end

  defp get_new_position(socket, "", key, _) do
    x = socket.assigns.player_x
   {x, "", 0}
  end

  defp get_new_position(socket, text_to_type, key, extra_letters) do
    x_old = socket.assigns.player_x
    <<head :: binary-size(1)>> <> rest = text_to_type

    {x, text_to_type, extra_letters} =
      case {key, extra_letters} do
        {k, 0} when k in [head] -> {x_old + 1, rest, 0}
        {"Backspace", 0} -> {x_old, text_to_type, extra_letters}
        {"Backspace", _} -> {x_old, text_to_type, extra_letters-1}
        {k, _} when k not in [head] -> {x_old, text_to_type, extra_letters+1}
        {_, _} -> {x_old, text_to_type, extra_letters+1}
      end

    # IO.inspect(extra_letters)

    x =
      if x in 1..@track_length do
        x
      else
        x_old
      end

    {x, text_to_type, extra_letters}
  end

end

