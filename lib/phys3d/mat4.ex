defmodule Phys3D.Mat4 do
  alias Phys3D.Math
  alias Phys3D.Mat3
  alias Phys3D.Vec3
  alias Phys3D.Vec4

  @type t :: {Vec4.t(), Vec4.t(), Vec4.t(), Vec4.t()}

  @spec flatten(matrix :: t()) ::
          {float(), float(), float(), float(), float(), float(), float(), float(), float(),
           float(), float(), float(), float(), float(), float(), float()}
  def flatten({{a0, a1, a2, a3}, {b0, b1, b2, b3}, {c0, c1, c2, c3}, {d0, d1, d2, d3}}) do
    {a0, a1, a2, a3, b0, b1, b2, b3, c0, c1, c2, c3, d0, d1, d2, d3}
  end

  @spec zero() :: t()
  def zero() do
    {
      Vec4.new(0, 0, 0, 0),
      Vec4.new(0, 0, 0, 0),
      Vec4.new(0, 0, 0, 0),
      Vec4.new(0, 0, 0, 0)
    }
  end

  @spec identity() :: t()
  def identity() do
    {
      Vec4.new(1, 0, 0, 0),
      Vec4.new(0, 1, 0, 0),
      Vec4.new(0, 0, 1, 0),
      Vec4.new(0, 0, 0, 1)
    }
  end

  @spec trace(mat :: t()) :: float()
  def trace({{r0x, _, _, _}, {_, r1y, _, _}, {_, _, r2z, _}, {_, _, _, r3w}}) do
    r0x * r0x + r1y * r1y + r2z * r2z + r3w * r3w
  end

  @spec determinant(mat :: t()) :: float()
  def determinant(mat) do
    Enum.reduce(0..3, 0, fn j, acc ->
      minor_mat = minor(mat, 0, j)
      cofactor = elem(mat, 0) |> elem(j)
      sign = if rem(j, 2) == 0, do: 1, else: -1
      acc + cofactor * Mat3.determinant(minor_mat) * sign
    end)
  end

  @spec transpose(mat :: t()) :: t()
  def transpose(mat) do
    mat
    |> Tuple.to_list()
    |> Enum.map(&Tuple.to_list/1)
    |> Enum.zip()
    |> List.to_tuple()
  end

  @spec inverse(mat :: t()) :: t()
  def inverse(mat) do
    inv = for i <- 0..3 do
      for j <- 0..3 do
        cofactor(mat, i, j)
      end
    end
    |> Enum.map(&List.to_tuple/1)
    |> List.to_tuple()

    inv_det = 1 / determinant(mat)

    scale(inv, inv_det)
  end

  @spec minor(mat :: t(), i :: integer(), j :: integer) :: Mat3.t()
  def minor(m, i, j) do
    rows = Tuple.to_list(m)

    minor_rows =
      rows
      |> Enum.with_index()
      |> Enum.reject(fn {_row, y} -> y == j end)
      |> Enum.map(fn {row, _y} ->
        row
        |> Tuple.to_list()
        |> Enum.with_index()
        |> Enum.reject(fn {_value, x} -> x == i end)
        |> Enum.map(&elem(&1, 0))
        |> List.to_tuple()
      end)

    List.to_tuple(minor_rows)
  end

  @spec cofactor(mat :: t(), i :: integer(), j :: integer()) :: float()
  def cofactor(mat, i, j) do
    :math.pow(-1, i + 1 + j + 1) * Mat3.determinant(minor(mat, i, j))
  end

  @spec orient(pos :: Vec3.t(), fwd :: Vec3.t(), up :: Vec3.t()) :: t()
  def orient({px, py, pz}, {fx, fy, fz} = fwd, {ux, uy, uz} = up) do
    {lx, ly, lz} = Vec3.cross(up, fwd)

    # this is for the physics coordinate system where
    # +x-axis = fwd
    # +y-axis = left
    # +z-axis = up
    # this I think will be weird with opengl?
    {
      Vec4.new(fx, lx, ux, px),
      Vec4.new(fy, ly, uy, py),
      Vec4.new(fz, lz, uz, pz),
      Vec4.new(0, 0, 0, 1)
    }
  end

  @spec scale(mat :: t(), scalar :: number()) :: t()
  def scale({r0, r1, r2, r3}, scalar) do
    {
      Vec4.scale(r0, scalar),
      Vec4.scale(r1, scalar),
      Vec4.scale(r2, scalar),
      Vec4.scale(r3, scalar)
    }
  end

  @spec add(m1 :: t(), m2 :: t()) :: t()
  def add({r0, r1, r2, r3}, {s0, s1, s2, s3}) do
    {
      Vec4.add(r0, s0),
      Vec4.add(r1, s1),
      Vec4.add(r2, s2),
      Vec4.add(r3, s3)
    }
  end

  @spec look_at(eye :: Vec3.t(), center :: Vec3.t(), up :: Vec3.t()) :: t()
  def look_at(eye, center, up) do
    f =
      center
      |> Vec3.subtract(eye)
      |> Vec3.normalize()

    s =
      f
      |> Vec3.cross(up)
      |> Vec3.normalize()

    u = Vec3.cross(s, f)

    {f0, f1, f2} = f
    {s0, s1, s2} = s
    {u0, u1, u2} = u

    # same not as with orient/2; this coordinate system is wrong for opengl
    # .. I think
    {
      {s0, u0, -f0, 0.0},
      {s1, u1, -f1, 0.0},
      {s2, u2, -f2, 0.0},
      {-Vec3.dot(s, eye), -Vec3.dot(u, eye), Vec3.dot(f, eye), 1.0}
    }
  end

  @spec perspective(fovy :: float(), aspect :: float(), near :: float(), far :: float()) :: t()
  def perspective(fovy, aspect, near, far) do
    fovy_radians = Math.radian(fovy)
    f = 1.0 / :math.tan(fovy_radians * 0.5)
    y_scale = f / aspect

    {
      Vec4.new(f, 0, 0, 0),
      Vec4.new(0, y_scale, 0, 0),
      Vec4.new(0, 0, (far + near) / (near - far), (2 * far * near) / (near - far)),
      Vec4.new(0, 0, -1, 0)
    }
    # {
    #   {f, 0.0, 0.0, 0.0},
    #   {0.0, f, 0.0, 0.0},
    #   {0.0, 0.0, (far + near) * nf, -1.0},
    #   {0.0, 0.0, 2 * far * near * nf, 0.0}
    # }
  end

  @spec ortho(x_min :: float(), x_max :: float(), y_min :: float(), y_max :: float(), z_near :: float(), z_far :: float()) :: t()
  def ortho(x_min, x_max, y_min, y_max, z_near, z_far) do
    width = x_max - x_min
    height = y_max - y_min
    depth = z_far - z_near

    tx = -(x_max + x_min) / width
    ty = -(y_max + y_min) / height
    tz = -(z_far + z_near) / depth

    {
      Vec4.new(2 / width, 0, 0, tx),
      Vec4.new(0, 2 / height, 0, ty),
      Vec4.new(0, 0, -2 / depth, tz),
      Vec4.new(0, 0, 0, 1)
    }
  end

  @spec to_binary(matrix :: t()) :: binary()
  def to_binary({a, b, c, d}) do
    Vec4.to_binary(a) <> Vec4.to_binary(b) <> Vec4.to_binary(c) <> Vec4.to_binary(d)
  end
end
