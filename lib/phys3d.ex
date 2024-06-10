defmodule Phys3D do
  alias Phys3D.Model
  alias Phys3D.Mesh
  alias Phys3D.Sphere
  alias Phys3D.Quat
  alias Phys3D.Body
  alias Phys3D.Scene
  alias Phys3D.Camera
  alias Phys3D.Mat4
  alias Phys3D.OpenGL
  alias Phys3D.Shader
  alias Phys3D.Vec3
  alias Phys3D.Window

  import Phys3D.WxRecords
  import Bitwise, only: [|||: 2]

  @behaviour :wx_object

  def start do
    :wx_object.start_link(__MODULE__, [], [])
  end

  def init(_args) do
    # frame, canvas, ctx
    window = Window.init()

    shader_program = Shader.init("shaders/vertex.vs", "shaders/fragment.fs")

    # vao
    opengl = OpenGL.init()

    {body_id, body} = Body.new(%{
      position: Vec3.new(0, 0, 0),
      orientation: Quat.new(Vec3.new(0, 0, 0), 1),
      shape: Sphere.new(1),
    })

    scene = Scene.init(Map.put(%{}, body_id, body))

    {obj, _mtl} = Model.load("sphere_ex")
    mesh = Mesh.new(obj.v, obj.fv, obj[:fn])

    state = %{
      shader_program: shader_program,
      keys: %{},
      camera: %Camera{},
      last_x: nil,
      last_y: nil,
      dt: 1,
      t: :erlang.system_time(:millisecond),
      scene: scene,
      mesh: mesh,
    }

    {model, view, projection} = create_matrices(state)

    gl_stuff = %{
      matrices: %{
        model: model,
        view: view,
        projection: projection
      },
      locations: %{
        model: :gl.getUniformLocation(shader_program, ~c"model"),
        view: :gl.getUniformLocation(shader_program, ~c"view"),
        projection: :gl.getUniformLocation(shader_program, ~c"projection"),
        color: :gl.getUniformLocation(shader_program, ~c"color")
      }
    }

    state =
      state
      |> Map.merge(window)
      |> Map.merge(opengl)
      |> Map.merge(gl_stuff)

    send(self(), :update)

    {window.frame, state}
  end

  def handle_event(wx(event: wxClose()), state) do
    IO.puts("closing")
    {:stop, :normal, state}
  end

  def handle_event(wx(event: wxKey(type: :key_down, keyCode: key_code)), state) do
    state = %{state | keys: Map.put(state.keys, key_code, true)}

    if key_code == ?L do
      :wxWindow.releaseMouse(state.canvas)
      :wxWindow.setCursor(state.canvas, :wx_const.wx_null_cursor())
    end

    {:noreply, state}
  end

  def handle_event(wx(event: wxKey(type: :key_up, keyCode: key_code)), state) do
    state = %{state | keys: Map.put(state.keys, key_code, false)}

    {:noreply, state}
  end

  def handle_event(wx(event: wxMouse(type: :motion, x: x, y: y)), state) do
    {lx, ly} = unless state.last_x, do: {x, y}, else: {state.last_x, state.last_y}

    sensitivity = state.dt / 100_000
    x_offset = (x - lx) * sensitivity
    y_offset = (ly - y) * sensitivity

    new_yaw = state.camera.yaw + x_offset
    new_pitch = state.camera.pitch + y_offset

    new_pitch =
      cond do
        new_pitch > 89.0 -> 89.0
        new_pitch < -89.0 -> -89.0
        true -> new_pitch
      end

    camera = Camera.point(state.camera, new_pitch, new_yaw)

    state = %{
      state
      | camera: camera,
        last_x: x,
        last_y: y
    }

    {:noreply, state}
  end

  def handle_event(_request, state) do
    {:noreply, state}
  end

  def handle_sync_event(_event, _object, _state) do
    # this is here just to test event callbacks being in a separate process
    IO.inspect(self(), label: "handle_sync_event")

    :ok
  end

  def handle_info(:update, state) do
    :wx.batch(fn ->
      render(state)
    end)

    state = update_camera(state)

    {model, view, projection} = create_matrices(state)

    time = :erlang.system_time(:millisecond)

    state = %{
      state
      | dt: time - state.t,
        t: time,
        matrices: %{
          model: model,
          view: view,
          projection: projection
        }
    }

    {:noreply, state}
  end

  defp render(%{canvas: canvas} = state) do
    draw(state)
    :wxGLCanvas.swapBuffers(canvas)
    send(self(), :update)
    IO.inspect(state)
    :ok
  end

  defp draw(%{shader_program: shader_program, mesh: mesh} = state) do
    :gl.clearColor(0.4, 0.5, 0.6, 1.0)
    :gl.clear(:gl_const.gl_color_buffer_bit() ||| :gl_const.gl_depth_buffer_bit())

    :gl.useProgram(shader_program)

    :gl.polygonMode(:gl_const.gl_front_and_back(), :gl_const.gl_fill())
    :gl.uniform3f(state.locations.color, 0.1, 0.2, 0.3)

    set_uniform_matrix(state.locations.model, state.matrices.model)
    set_uniform_matrix(state.locations.view, state.matrices.view)
    set_uniform_matrix(state.locations.projection, state.matrices.projection)

    # :gl.bindVertexArray(vao)

    # :gl.drawElements(:gl_const.gl_triangles, 36, :gl_const.gl_unsigned_int, 0)
    # :gl.drawElementsInstanced(
    #   :gl_const.gl_triangles(),
    #   36,
    #   :gl_const.gl_unsigned_int(),
    #   0,
    #   50 * 50 * 50
    # )

    Mesh.draw(mesh, shader_program)

    :ok
  end

  def update_camera(%{camera: camera, keys: keys} = state) do
    speed = state.dt / 100
    new_pos = camera.pos

    new_pos =
      if Map.get(keys, ?W) do
        Vec3.add(new_pos, Vec3.scale(camera.front, speed))
      else
        new_pos
      end

    new_pos =
      if Map.get(keys, ?S) do
        Vec3.subtract(new_pos, Vec3.scale(camera.front, speed))
      else
        new_pos
      end

    new_pos =
      if Map.get(keys, ?A) do
        Vec3.subtract(
          new_pos,
          Vec3.scale(Vec3.normalize(Vec3.cross(camera.front, camera.up)), speed)
        )
      else
        new_pos
      end

    new_pos =
      if Map.get(keys, ?D) do
        Vec3.add(
          new_pos,
          Vec3.scale(Vec3.normalize(Vec3.cross(camera.front, camera.up)), speed)
        )
      else
        new_pos
      end

    new_pos =
      if Map.get(keys, :wx_const.wxk_space()) do
        Vec3.add(new_pos, Vec3.scale(camera.up, speed))
      else
        new_pos
      end

    new_pos =
      if Map.get(keys, :wx_const.wxk_raw_control()) do
        Vec3.subtract(new_pos, Vec3.scale(camera.up, speed))
      else
        new_pos
      end

    %{state | camera: %{camera | pos: new_pos}}
  end

  def create_matrices(%{camera: camera}) do
    model = Mat4.identity()
    view = Mat4.look_at(camera.pos, Vec3.add(camera.pos, camera.front), camera.up)
    projection = Mat4.perspective(:math.pi() / 4, 800.0 / 600.0, 0.1, 100.0)

    {model, view, projection}
  end

  def set_uniform_matrix(location, matrix) do
    :gl.uniformMatrix4fv(location, :gl_const.gl_false(), [Mat4.flatten(matrix)])
  end
end