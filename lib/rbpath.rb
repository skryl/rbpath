require "rbpath/version"

module RbPath
  autoload :Query, 'rbpath/query'
  autoload :Utils, 'rbpath/utils'
  autoload :ObjectMixin, 'rbpath/object_mixin'
  autoload :ClassMixin,  'rbpath/class_mixin'

  def self.included(klass)
    klass.send(:include, RbPath::ObjectMixin)
    klass.extend RbPath::ClassMixin
  end

  def self.extended(obj)
    obj.singleton_class.send(:include, RbPath::ObjectMixin)
  end
end
