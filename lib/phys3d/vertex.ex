defmodule Phys3D.Vertex do
  alias Phys3D.Vec2
  alias Phys3D.Vec3

  defstruct [position: Vec3.new(0, 0, 0), normal: Vec3.new(0, 0, 0), tex_coords: Vec2.new(0, 0)]
end
