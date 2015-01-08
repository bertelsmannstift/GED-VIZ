class Object
  def own_methods
    (methods - (self.class.ancestors - [self.class]).collect { |k| k.instance_methods }.flatten).sort
  end
end