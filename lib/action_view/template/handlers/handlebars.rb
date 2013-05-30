module ActionView
  class Template
    module Handlers
      class Handlebars

        def self.call(template)
          <<-SOURCE
          variable_names = controller.instance_variable_names
          variable_names -= %w[@template]
          if controller.respond_to?(:protected_instance_variables)
            variable_names -= controller.protected_instance_variables
          end
          variable_names.reject! { |name| name.starts_with? '@_' }

          variables = variable_names.inject({}) { |acc,name| acc[name.sub(/^@/, "")] = controller.instance_variable_get(name); acc }
          variables.merge!(local_assigns)

          #{self.name}.render_template(self, #{template.source.inspect}, variables, "#{template.virtual_path}", "#{template.inspect}").html_safe
          SOURCE
        end

        def self.render_template(scope, data, variables, pathname, fullpath)
          # TODO: you should be able to chain multiple template handlers together here if you want
          # e.g. HAML + SLIM + ...; not sure about performance implications if any
          data =
            if fullpath.end_with? ".hamlbars"
              Haml::Engine.new(data, HandlebarsAssets::Config.haml_options).render(scope, variables)
            elsif fullpath.end_with? ".slimbars"
              Slim::Template.new(HandlebarsAssets::Config.slim_options) { data }.render(scope, variables)
            else
             data
            end

          # TODO: this is almost the exact same code from evaluate in handlebars_assets/tilt_handlebars.rb
          precompiled_template = HandlebarsAssets::Handlebars.precompile(data)
          HandlebarsAssets::Handlebars.runtime_context.eval("Handlebars.template(#{precompiled_template})(#{variables.to_json})")
        end
      end
    end
  end
end
