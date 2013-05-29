module ActionView
  class Template
    module Handlers

      class HBS
        # include HandlebarsAssets::Unindent

        def self.call(template)
          new.call(template)
        end

        def call(template)
          <<-HBS
          variable_names = controller.instance_variable_names
          variable_names -= %w[@template]
          if controller.respond_to?(:protected_instance_variables)
            variable_names -= controller.protected_instance_variables
          end
          variable_names.reject! { |name| name.starts_with? '@_' }

          variables = variable_names.inject({}) { |acc,name| acc[name.sub(/^@/, "")] = controller.instance_variable_get(name); acc }
          variables.merge!(local_assigns)

          template_source = Haml::Engine.new(#{template.source.inspect}, HandlebarsAssets::Config.haml_options).render(self, variables)
          HandlebarsAssets::Handlebars.render(template_source, variables).html_safe
          HBS
        end
      end

    end
  end
end
