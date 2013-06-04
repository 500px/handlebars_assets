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
          # use context here because it will have the preloaded especially in the RAILS case (DEV).
          $stderr.puts "RENDERING ACTIONVIEW: #{pathname}" # TODO: use sprockets lookup

          # TODO: application specific tweak for now, makes auto-update of the context when render occurs
          Rails.application.assets[pathname.to_s] # Auto Update?

          template_namespace = HandlebarsAssets::Config.template_namespace
          HandlebarsAssets::Handlebars.context.eval("this.#{template_namespace}['#{pathname}'](#{variables.to_json})")
        end
      end
    end
  end
end
