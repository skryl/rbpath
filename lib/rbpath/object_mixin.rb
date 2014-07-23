module RbPath::ObjectMixin

  def query(*query)
    RbPath::Query.new(*query).query(self)
  end

  def pquery(*query)
    RbPath::Query.new(*query).pquery(self)
  end

  def path_values(paths)
    RbPath::Query.new(*query).values_at(self, paths)
  end

  # The object's class may not have the ClassMixin if a singleton object
  # was extended:
  #
  # h = { a: 1, b: 2}
  # h.extend RbPath
  #
  def rbpath_fields
    self.class.respond_to?(:rbpath_fields) ?
      self.class.rbpath_fields : nil
  end

end
