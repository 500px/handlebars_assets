require 'tilt'

module HandlebarsAssets
  module Unindent
    # http://bit.ly/aze9FV
    # Strip leading whitespace from each line that is the same as the
    # amount of whitespace on the first line of the string.
    # Leaves _additional_ indentation on later lines intact.
    def unindent(heredoc)
      heredoc.gsub(/^#{heredoc[/\A\s*/]}/, '')
    end
  end

  class TiltHandlebars < Tilt::Template

    include Unindent

    def self.default_mime_type
      'application/javascript'
    end

    def evaluate(scope, locals, &block)
      template_path = TemplatePath.new(scope)
      scope.instance_variable_set :@virtual_path, template_path.name

      # TODO: I think this could be removed by registering differently (will test in future)
      source =
       if template_path.is_haml?
         Haml::Engine.new(data, HandlebarsAssets::Config.haml_options).render(scope, locals)
       elsif template_path.is_slim?
         Slim::Template.new(HandlebarsAssets::Config.slim_options) { data }.render(scope, locals)
       else
         data
       end


      template_namespace = HandlebarsAssets::Config.template_namespace

      compiled_hbs = HandlebarsAssets::Handlebars.precompile(source, HandlebarsAssets::Config.options)

      $stderr.puts "HANDLEBARS #{template_namespace}[#{template_path.name}] registered"
      template =
        if template_path.is_partial?
          unindent <<-PARTIAL
            (function() {
              this.#{template_namespace} || (this.#{template_namespace} = {});
              this.#{template_namespace}[#{template_path.name}] = Handlebars.template(#{compiled_hbs});
              Handlebars.registerPartial(#{template_path.name}, this.#{template_namespace}[#{template_path.name}]);
              return this.#{template_namespace}[#{template_path.name}];
            }).call(this);
            PARTIAL
        else
          unindent <<-TEMPLATE
            (function() {
              this.#{template_namespace} || (this.#{template_namespace} = {});
              this.#{template_namespace}[#{template_path.name}] = Handlebars.template(#{compiled_hbs});
              return this.#{template_namespace}[#{template_path.name}];
            }).call(this);
          TEMPLATE
        end
      HandlebarsAssets::Handlebars.context.exec(template) # make the context have the compiled version

      template
    end

    protected

    def prepare; end

    # TODO: remove this ...
    class TemplatePath
      def initialize(scope)
        self.full_path = scope.pathname.to_path
        self.template_path = scope.logical_path
      end

      def is_haml?
        full_path.to_s.end_with?('.hamlbars')
      end

      def is_slim?
        full_path.to_s.end_with?('.slimbars')
      end

      def is_partial?
        template_path.gsub(%r{.*/}, '').start_with?('_')
      end

      def name
        template_name
      end

      private

      attr_accessor :full_path, :template_path

      def relative_path
        template_path.gsub(/^#{HandlebarsAssets::Config.path_prefix}\/(.*)$/i, "\\1")
      end

      def template_name
        relative_path.dump
      end
    end
  end
end
