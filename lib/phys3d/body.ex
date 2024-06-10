defmodule Phys3D.Body do
  defstruct [:position, :orientation, :shape]

  def new(%{position: position, orientation: orientation, shape: shape}) do
    {:rand.uniform(1_000_000), %__MODULE__{
      position: position,
      orientation: orientation,
      shape: shape,
    }}
  end
end
