module RbPath::ClassMixin

  def rbpath(*fields)
    @_rbpath_fields_ = fields.map(&:to_s)
  end

  def rbpath_fields
    @_rbpath_fields_
  end

end
