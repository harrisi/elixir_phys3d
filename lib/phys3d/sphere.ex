defmodule Phys3D.Sphere do
  defstruct [radius: 1.0]

  def init(_) do
    # expect radius, subdivision, and smooth as args
    radius = 1
    subdivision = 3
    smooth = true

    %{
      radius: radius,
      subdivision: subdivision,
      smooth: smooth,

      vertex_count_per_row: :math.pow(2, subdivision) + 1,
    }
  end

  def new(radius) do
    %__MODULE__{
      radius: radius,
    }
  end

  def get_unit_positive_x(points_per_row) do
    d2r = :math.pi / 180

    # vertices = [3 * points_per_row * points_per_row] # size
    # n1 = {0, 0, 0} # normal of longitudinal plane rotating along y-axis
    # n2 = {0, 0, 0} # normal of latitudinal plane rotating along z-axis
    # v = {0, 0, 0} # direction vector intersecting 2 planes, n1 x n2
    # a1 = nil # longitudinal angle along y-axis (-45 ~ +45)
    # a2 = nil # latitudinal angle along z-axis (+45 ~ -45)
    # scale = nil
    # # i = 0; j = 0; k = 0
    # k = 0

    #rotate latitudinal plane from 45 to -45 degress along z-axis
    vertices = for i <- 0..(points_per_row - 1) do
      # normal for latitudinal plane
      a2 = d2r * (45 - 90 * i / (points_per_row - 1))
      # n2[0] = -:math.sin(a2)
      # n2[1] = :math.cos(a2)
      # n2[2] = 0
      {n2x, n2y, n2z} = {-:math.sin(a2), :math.cos(a2), 0}

      # rotate longitudinal plane from -45 to 45 along y-axis
      for j <- 0..(points_per_row - 1) do
        # normal for longitudinal plane
        a1 = d2r * (-45 + 90 * j / (points_per_row - 1))
        # n1[0] = -:math.sin(a1)
        # n1[1] = 0
        # n1[2] = -:math.cos(a1)
        {n1x, n1y, n1z} = {-:math.sin(a1), 0, -:math.cos(a1)}

        # find direction vector of intersected line, n1 x n2
        # v[0] = n1[1] * n2[2] - n1[2] * n2[1]
        # v[1] = n1[2] * n2[0] - n1[0] * n2[2]
        # v[2] = n1[0] * n2[1] - n1[1] * n2[0]
        v = {
          n1y * n2z - n1z * n2y,
          n1z * n2x - n1x * n2z,
          n1x * n2y - n1y * n2x
        }

        # normalize direction vector
        scale = compute_scale_for_length(v, 1)
        v = scale_vertex(v, scale)

        # vertices[k] = v[0]
        # vertices[k + 1] = v[1]
        # vertices[k + 2] = v[2]
        # k = k + 3

        v
      end
    end

    vertices
  end

  # I have this already somewhere else
  def compute_scale_for_length({vx, vy, vz}, length) do
    length / :math.sqrt(vx * vx + vy * vy + vz * vz)
  end

  # I have this too
  def scale_vertex({vx, vy, vz}, scale) do
    {vx * scale, vy * scale, vz * scale}
  end

  def resize_arrays_smooth() do
    # clear arrays
    # make new arrays for vertices, normals, texCoords, indices
  end

  def add_vertex(index, x, y, z) do
    # just appends {x, y, z} to vertices
  end

  def add_normal(index, x, y, z) do
    # just appends {x, y, z} to normals
  end

  def add_tex_coords(index, s, t) do
    # just appends {s, t} to tex_cords
  end

  def add_indices(index, i1, i2, i3) do
    # just appends {i1, i2, i3} to indices
  end

  def build_vertices_smooth(sphere) do
    # these would be part of the state
    vertex_count_per_row = 5
    radius = 1

    unit_vertices = get_unit_positive_x(vertex_count_per_row)

    # resize_arrays_smooth()

    {x, y, z, s, t} = {0, 0, 0, 0, 0}
    {i, j, k, k1, k2, ii, jj, kk} = {0, 0, 0, 0, 0, 0, 0, 0}

    for i <- 0..(vertex_count_per_row - 1) do
      k1 = i * vertex_count_per_row # index for current row
      k2 = k1 + vertex_count_per_row # index for next row
      t = i / (vertex_count_per_row - 1)

      for j <- 0..(vertex_count_per_row - 1) do # ++j, ++k1, ++k2
        # these should be {x, y, z} = unit_vertices.. somehow
        x = unit_vertices[k]
        y = unit_vertices[k + 1]
        z = unit_vertices[k + 2]
        s = j / (vertex_count_per_row - 1)
        # I think I need to build up a list here in reverse.
        add_vertex(ii, x * radius, y * radius, z * radius)
        add_normal(ii, x, y, z)
        add_tex_coords(jj, s, t)

        # this doesn't work, and it's just to stop the last index from
        # overflowing, basically. I could return a value from add_indices
        # instead, I think.
        if i < (vertex_count_per_row - 1) and j < (vertex_count_per_row - 1) do
          add_indices(kk, k1, k2, k1 + 1)
          kk = kk + 3
          add_indices(kk, k1 + 1, k2, k2 + 1)
          kk = kk + 3
        end

        ii = ii + 3
        jj = jj + 2
        k = k + 3
      end
    end
  end

end

# defimpl Phys3D.Shape, for: Phys3D.Sphere do
#   def type(_sphere), do: :sphere

#   def draw(gl, sphere) do
#     # how can we do this?
#     # should we have each shape be a genserver, and handle_call?
#     # or can we pass `init` the gl context and build buffer objects, then when
#     # the scene goes through the bodies, just cast all of them, which will cast
#     # back with the object positions?
#   end

#   # I think the above doesn't really make sense. what about the following:
#   # the application creates a scene, which has shapes. after you add a shape to
#   # the scene, what happens? does the shape periodically send information to the
#   # scene? does the scene periodically ask all the shapes for an update?
# end
