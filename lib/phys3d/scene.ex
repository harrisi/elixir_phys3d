defmodule Phys3D.Scene do
  use GenServer

  alias Phys3D.Shape
  alias Phys3D.Sphere
  alias Phys3D.Quat
  alias Phys3D.Vec3
  alias Phys3D.Body

  def init(bodies) do
    {:ok, %{
      t: :erlang.monotonic_time(:millisecond),
      dt: 1,
      bodies: bodies,
    }}
  end

  def handle_cast(:update, state) do
    t = :erlang.monotonic_time(:millisecond)
    dt = t - state.t

    # then draw the bodies.

    state.bodies
    |> Enum.each(fn el ->
      Shape.draw(el)
    end)

    {:noreply, %{state |
    t: t,
    dt: dt,
    }}
  end

  def handle_cast({:insert, body}, state) do
    {:noreply, %{state | bodies: [body | state.bodies]}}
  end
end
