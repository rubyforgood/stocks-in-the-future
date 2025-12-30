# frozen_string_literal: true

class BasePresenter
  attr_reader :object

  def initialize(object)
    @object = object
  end

  def method_missing(method_name, *, &)
    if object.respond_to?(method_name)
      object.public_send(method_name, *, &)
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    object.respond_to?(method_name) || super
  end
end
