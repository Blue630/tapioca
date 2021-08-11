# typed: strict
# frozen_string_literal: true

begin
  require "active_model"
rescue LoadError
  return
end

module Tapioca
  module Compilers
    module Dsl
      # `Tapioca::Compilers::Dsl::ActiveModelAttributes` decorates RBI files for all
      # classes that use [`ActiveModel::Attributes`](https://edgeapi.rubyonrails.org/classes/ActiveModel/Attributes/ClassMethods.html).
      #
      # For example, with the following class:
      #
      # ~~~rb
      # class Shop
      #   include ActiveModel::Attributes
      #
      #   attribute :name, :string
      # end
      # ~~~
      #
      # this generator will produce an RBI file with the following content:
      # ~~~rbi
      # # typed: true
      #
      # class Shop
      #
      #   sig { returns(::String) }
      #   def name; end
      #
      #   sig { params(name: ::String).returns(::String) }
      #   def name=(name); end
      # end
      # ~~~
      class ActiveModelAttributes < Base
        extend T::Sig

        sig { override.params(root: RBI::Tree, constant: T.all(Class, ::ActiveModel::Attributes::ClassMethods)).void }
        def decorate(root, constant)
          attribute_methods = attribute_methods_for(constant)
          return if attribute_methods.empty?

          root.create_path(constant) do |klass|
            attribute_methods.each do |method, attribute_type|
              generate_method(klass, method, attribute_type)
            end
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          all_classes.grep(::ActiveModel::Attributes::ClassMethods)
        end

        private

        sig { params(constant: ::ActiveModel::Attributes::ClassMethods).returns(T::Array[[::String, ::String]]) }
        def attribute_methods_for(constant)
          constant.attribute_method_matchers.flat_map do |matcher|
            constant.attribute_types.map do |name, value|
              [matcher.method_name(name), type_for(value)]
            end
          end
        end

        sig { params(attribute_type_value: ::ActiveModel::Type::Value).returns(::String) }
        def type_for(attribute_type_value)
          case attribute_type_value
          when ActiveModel::Type::Boolean
            "T::Boolean"
          when ActiveModel::Type::Date
            "::Date"
          when ActiveModel::Type::DateTime, ActiveModel::Type::Time
            "::DateTime"
          when ActiveModel::Type::Decimal
            "::BigDecimal"
          when ActiveModel::Type::Float
            "::Float"
          when ActiveModel::Type::Integer
            "::Integer"
          when ActiveModel::Type::String
            "::String"
          else
            "T.untyped"
          end
        end

        sig { params(klass: RBI::Scope, method: String, type: String).void }
        def generate_method(klass, method, type)
          if method.end_with?("=")
            parameter = create_param("value", type: type)
            klass.create_method(
              method,
              parameters: [parameter],
              return_type: type
            )
          else
            klass.create_method(method, return_type: type)
          end
        end
      end
    end
  end
end