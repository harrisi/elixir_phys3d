defmodule Phys3D.Vec2 do
  @type t :: {float(), float()}

  @spec new(x :: number(), y :: number()) :: t()
  def new(x, y) do
    {x + 0.0, y + 0.0}
  end

  @spec add(v1 :: t(), v2 :: t()) :: t()
  def add({x1, y1}, {x2, y2}) do
    {x1 + x2, y1 + y2}
  end

  @spec subtract(v1 :: t(), v2 :: t()) :: t()
  def subtract({x1, y1}, {x2, y2}) do
    {x1 - x2, y1 - y2}
  end

  @spec scale(v :: t(), scalar :: number()) :: t()
  def scale({x, y}, scalar) do
    {x * scalar, y * scalar}
  end

  @spec multiply(v1 :: t(), v2 :: t()) :: t()
  def multiply({x1, y1}, {x2, y2}) do
    {x1 * x2, y1 * y2}
  end

  @spec normalize(v :: t()) :: t()
  def normalize({x, y} = v) do
    inv_mag = 1 / magnitude(v)
    {x * inv_mag, y * inv_mag}
  end

  @spec magnitude(v :: t()) :: float()
  def magnitude({x, y}) do
    :math.sqrt(x * x + y * y)
  end
end
