defprotocol Phys3D.Shape do
  @type t :: :sphere | :cube

  @spec type(t) :: t()
  def type(shape)

  @spec draw(t) :: nil
  def draw(shape)
end
