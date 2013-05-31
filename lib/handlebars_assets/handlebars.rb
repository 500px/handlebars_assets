# Based on https://github.com/josh/ruby-coffee-script
require 'execjs'
require 'pathname'

module HandlebarsAssets
  class Handlebars
    class << self

      def precompile(*args)
        # TODO: this should be cached probably...; why not just Handlebars['template_name'] (if exists) ???
        context.call('Handlebars.precompile', *args)
      end

      def runtime_context
        @runtime_context ||= ExecJS.compile("#{runtime_source};")
      end

      def context
        @context ||= ExecJS.compile(apply_patches_to_source)
      end

      def render(template, *args)
        locals = args.last.is_a?(Hash) ? args.pop : {}
        extra = args.first.to_s
        context_for(template, extra).call("template", locals.to_json)
      end

      protected

      attr_writer :source

      def append_patch(patch_file)
        self.source += patch_source(patch_file)
      end

      def apply_patches_to_source
        HandlebarsAssets::Config.patch_files.each do |patch_file|
          append_patch(patch_file)
        end
        puts "SRC=#{source}"
        source
      end

      def source
        @source ||= path.read
      end

      def patch_path
        @patch_path ||= Pathname(HandlebarsAssets::Config.patch_path)
      end

      def patch_source(patch_file)
        patch_path.join(patch_file).read
      end

      def runtime_source
        return @runtime if @runtime
        @runtime ||= runtime_path.read
        HandlebarsAssets::Config.patch_files.each do |patch_file|
          @runtime << "\n;"
          @runtime << patch_source(patch_file)
          @runtime << "\n;"
        end
        puts @runtime
        @runtime
      end

      def path
        @path ||= assets_path.join(HandlebarsAssets::Config.compiler)
      end

      def runtime_path
        @runtime_path ||= assets_path.join(HandlebarsAssets::Config.compiler_runtime)
      end

      def assets_path
        @assets_path ||= Pathname(HandlebarsAssets::Config.compiler_path)
      end
    end
  end
end
