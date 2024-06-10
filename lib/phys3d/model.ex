defmodule Phys3D.Model do
  defstruct [meshes: [], directory: nil]

  def draw(shader) do

  end

  def load(path) do
    path = Path.join("priv/models", path)
    obj_source = File.read!(path <> ".obj")
    mtl_source = File.read!(path <> ".mtl")

    obj = obj_parse(obj_source)
    mtl = mtl_parse(mtl_source)

    {obj, mtl}
  end

  defp obj_parse(obj_source) do
    split = String.split(obj_source, "\r\n")

    do_obj_parse(split, %{
      v: [],
      vn: [],
      vt: [],
      vp: [],
      f: [],
      fv: [],
      ft: [],
      fn: [],
      l: [],
      o: nil,
      mtllib: nil,
      g: nil,
      usemtl: nil,
      s: nil,
      comments: [], # why not
    })
  end

  # generic helper to convert "a, b, c" to [a, b, c]
  # each value must be parsable as a float.
  defp get_abc(abc) do
    abc
    |> String.split()
    |> Enum.map(&(Float.parse(&1) |> elem(0)))
  end

  defp do_obj_parse([], acc) do
    %{
      acc |
      v: Enum.reverse(acc.v) |> List.flatten(),
      vn: Enum.reverse(acc.vn),
      f: Enum.reverse(acc.f),
      fv: Enum.reverse(acc.fv) |> List.flatten() |> Enum.map(&(&1 - 1)),
      ft: Enum.reverse(acc.ft),
      fn: Enum.reverse(acc[:fn]),
      comments: Enum.reverse(acc.comments),
    }
  end

  defp do_obj_parse(["" | tail], acc), do: do_obj_parse(tail, acc)

  defp do_obj_parse(["#" <> rest | tail], acc) do
    acc = %{acc | comments: [{-1, String.trim(rest)} | acc.comments]}

    do_obj_parse(tail, acc)
  end

  defp do_obj_parse(["v " <> vertex | tail], acc) do
    [x, y, z] = get_abc(vertex)

    acc = %{acc | v: [[x, y, z] | acc.v]}

    do_obj_parse(tail, acc)
  end

  defp do_obj_parse(["vn " <> vertex_normal | tail], acc) do
    [x, y, z] = get_abc(vertex_normal)

    acc = %{acc | vn: [{x, y, z} | acc.vn]}

    do_obj_parse(tail, acc)
  end

  defp do_obj_parse(["vt " <> vertex_texture | tail], acc) do
    [u, v] = vertex_texture
    |> String.split()
    |> Enum.map(&(Float.parse(&1) |> elem(0)))

    acc = %{acc | vt: [{u, v} | acc.vt]}

    do_obj_parse(tail, acc)
  end

  defp do_obj_parse(["vp " <> vertex_param | tail], acc) do
    [u, v] = vertex_param
    |> String.split()
    |> Enum.map(&(Float.parse(&1) |> elem(0)))

    acc = %{acc | vp: [{u, v} | acc.vp]}

    do_obj_parse(tail, acc)
  end

  defp do_obj_parse(["g " <> g | tail], acc) do
    unless acc.g do
      IO.puts(:stderr, "multiple g")
      IO.inspect({acc.g, g}, label: "multiple g, {old, new}")
    end

    acc = %{acc | g: g}

    do_obj_parse(tail, acc)
  end

  defp do_obj_parse(["usemtl " <> usemtl | tail], acc) do
    unless acc.usemtl do
      IO.puts(:stderr, "multiple usemtl")
      IO.inspect({acc.usemtl, usemtl}, label: "mutliple usemtl, {old, new}")
    end

    acc = %{acc | usemtl: usemtl}

    do_obj_parse(tail, acc)
  end

  # I think this is wrong, I think s acts like a stack?
  # yes. o, g, s, usemtl applies to the following element.
  defp do_obj_parse(["s " <> s | tail], acc) do
    unless acc.s do
      IO.puts(:stderr, "multiple s")
      IO.inspect({acc.s, s}, label: "multiple s, {old, new}")
    end

    acc = %{acc | s: s}

    do_obj_parse(tail, acc)
  end

  defp do_obj_parse(["f " <> face | tail], acc) do
    {a, b, c} = face
    # this needs to account for which type of pairing it is
    # it's actually always the same "pairing", as in there are three values
    # always, v, vt, and vn. I just didn't have a vt in my model.
    #
    # this is actually a triplet of values, f v1/vt1/vn1, where vt1 and vn1 may
    # be omitted. Wings outputs this as `f v1// ..`, `f v1//vn1 ..`, or, I
    # guess, `f v1/vt1/ ..`.
    # f ::= vertex (slash (vertex | blank)) (slash (vertex | blank))
    # vertex ::= number
    # slash ::= /
    # blank ::= epsilon
    |> String.split([" ", "/"])
    # this gives us ["1", "", "1", "2", "", "2", "3", "", "3"], for the string
    # "1//1 2//2 3//3". `Integer.parse/1` returns `:error` when passed an
    # empty string.
    # |> Enum.map(&(Integer.parse(&1) |> elem(0)))
    |> parse_face()
    # |> Enum.chunk_every(2)

    # really maybe I want fv, ft, fn so the indices are easier to access..
    acc = %{acc | f: [{a, b, c} | acc.f]}
    acc = %{acc | fv: [a | acc.fv], ft: [b | acc.ft], fn: [c | acc[:fn]]}

    do_obj_parse(tail, acc)
  end

  defp do_obj_parse(["o " <> obj | tail], acc) do
    unless acc.o do
      IO.puts(:stderr, "multiple o")
      IO.inspect({acc.o, obj}, label: "multiple o, {old, new}")
    end

    acc = %{acc | o: obj}

    do_obj_parse(tail, acc)
  end

  defp do_obj_parse(["mtllib " <> lib | tail], acc) do
    unless acc.mtllib do
      IO.puts(:stderr, "multiple mtllib")
      IO.inspect({acc.mtllib, lib}, label: "multiple mtllib, {old, new}")
    end

    acc = %{acc | mtllib: lib}

    do_obj_parse(tail, acc)
  end

  defp parse_maybe_face("") do
    nil
  end
  defp parse_maybe_face(f) do
    f
    |> Integer.parse()
    |> elem(0)
  end

  defp parse_face([fv1, fvt1, fn1, fv2, fvt2, fn2, fv3, fvt3, fn3]) do
    parsed_fv = [fv1, fv2, fv3]
    |> Enum.map(&(Integer.parse(&1) |> elem(0)))

    parsed_fvt = [fvt1, fvt2, fvt3]
    |> Enum.map(&parse_maybe_face/1)

    parsed_fn = [fn1, fn2, fn3]
    |> Enum.map(&parse_maybe_face/1)

    {parsed_fv, parsed_fvt, parsed_fn}
  end

  defp mtl_parse(mtl_source) do
    split = String.split(mtl_source, "\r\n")

    do_mtl_parse(split, %{
      newmtl: nil, # this is actually a command to start a new mtl
      # starts as nil
      # as we parse we build up an obj in it
      # when we parse a newmtl again, we push the contents of newmtl into
      # the list of materials and clear out newmtl
      materials: [],
      comments: [], # why not
    })
  end

  defp do_mtl_parse([], acc) do
    # make sure built up material is moved to materials
    %{acc | materials: [acc.newmtl | acc.materials]}
  end

  defp do_mtl_parse(["" | tail], acc), do: do_mtl_parse(tail, acc)
  defp do_mtl_parse(["#" <> comment | tail], acc) do
    acc = %{acc | comments: [{-1, comment} | acc.comments]}

    do_mtl_parse(tail, acc)
  end

  defp do_mtl_parse(["newmtl " <> newmtl | tail], acc) do
    acc = if acc.newmtl == nil do
      %{acc | newmtl: %{name: newmtl}}
    else
      %{acc | materials: [acc.newmtl | acc.materials], newmtl: nil}
    end

    do_mtl_parse(tail, acc)
  end

  defp do_mtl_parse(["Ns " <> ns | tail], acc) do
    {ns_parsed, ""} = Float.parse(ns)

    acc = put_in(acc.newmtl[:ns], ns_parsed)

    do_mtl_parse(tail, acc)
  end

  defp do_mtl_parse(["d " <> d | tail], acc) do
    {d_parsed, ""} = Float.parse(d)

    acc = put_in(acc.newmtl[:d], d_parsed)

    do_mtl_parse(tail, acc)
  end

  defp do_mtl_parse(["illum " <> illum | tail], acc) do
    {illum_parsed, ""} = Integer.parse(illum)

    acc = put_in(acc.newmtl[:illum], illum_parsed)

    do_mtl_parse(tail, acc)
  end

  defp do_mtl_parse(["Kd " <> kd | tail], acc) do
    [r, g, b] = get_abc(kd)

    acc = put_in(acc.newmtl[:kd], {r, g, b})

    do_mtl_parse(tail, acc)
  end

  defp do_mtl_parse(["Ka " <> ka | tail], acc) do
    [r, g, b] = get_abc(ka)

    acc = put_in(acc.newmtl[:ka], {r, g, b})

    do_mtl_parse(tail, acc)
  end

  defp do_mtl_parse(["Ks " <> ks | tail], acc) do
    [r, g, b] = get_abc(ks)

    acc = put_in(acc.newmtl[:ks], {r, g, b})

    do_mtl_parse(tail, acc)
  end

  defp do_mtl_parse(["Ke " <> ke | tail], acc) do
    [r, g, b] = get_abc(ke)

    acc = put_in(acc.newmtl[:ke], {r, g, b})

    do_mtl_parse(tail, acc)
  end
end
