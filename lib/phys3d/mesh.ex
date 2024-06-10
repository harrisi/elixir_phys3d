defmodule Phys3D.Mesh do
  defstruct [vertices: [], indices: [], textures: [], vao: 0, vbo: 0, ebo: 0]

  def new(%{vertices: vertices, indices: indices, textures: textures}) do
    new(vertices, indices, textures)
  end

  def new(vertices, indices, textures) do
    %__MODULE__{
      vertices: vertices,
      indices: indices,
      textures: textures,
    }
    |> setup()
  end

  def draw(%__MODULE__{vao: vao, indices: indices}, _shader) do
    # setup texture stuff. currently not using any.

    # indices |> IO.inspect(label: "indices")

    :gl.bindVertexArray(vao)
    :gl.drawElements(:gl_const.gl_triangles, length(indices), :gl_const.gl_unsigned_int, 0)
    :gl.bindVertexArray(0)
  end

  defp setup(%__MODULE__{} = mesh) do
    # stride = (3 + 3 + 2) * 4
    stride = 3 * 4

    [vao] = :gl.genVertexArrays(1)
    [vbo, ebo] = :gl.genBuffers(2)

    :gl.bindVertexArray(vao)
    :gl.bindBuffer(:gl_const.gl_array_buffer, vbo)

    :gl.bufferData(:gl_const.gl_array_buffer, length(mesh.vertices) * stride, make_bits(mesh.vertices), :gl_const.gl_static_draw)

    :gl.bindBuffer(:gl_const.gl_element_array_buffer, ebo)
    :gl.bufferData(:gl_const.gl_element_array_buffer, length(mesh.indices) * byte_size(<<0::unsigned-native>>), make_bits_unsigned(mesh.indices), :gl_const.gl_static_draw)

    :gl.enableVertexAttribArray(0)
    :gl.vertexAttribPointer(0, 3, :gl_const.gl_float, :gl_const.gl_false, stride, 0)

    # :gl.enableVertexAttribArray(1)
    # :gl.vertexAttribPointer(1, 3, :gl_const.gl_float, :gl_const.gl_false, stride, 3 * 4)

    # :gl.enableVertexAttribArray(2)
    # :gl.vertexAttribPointer(2, 2, :gl_const.gl_float, :gl_const.gl_false, stride, (3 + 3) * 4)

    :gl.bindVertexArray(0)

    %{
      mesh |
      vao: vao,
      vbo: vbo,
      ebo: ebo,
    }
  end

  defp make_bits(list) do
    list
    |> Enum.reduce(<<>>, fn el, acc -> acc <> <<el::float-native-size(32)>> end)
  end

  defp make_bits_unsigned(list) do
    list
    |> Enum.reduce(<<>>, fn el, acc -> acc <> <<el::unsigned-native>> end)
  end
end
