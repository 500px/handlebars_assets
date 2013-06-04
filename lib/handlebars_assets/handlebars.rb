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

      def context
        @context ||= ExecJS.compile(source)
      end

      protected

      attr_writer :source

      def source
        @source = path.read
        HandlebarsAssets::Config.patch_files.each do |patch_file|
          # TODO: what happens when a patch file goes stale (e.g. development)
          @source += Rails.application.assets[patch_file].body
        end
        @source
      end

      def patch_path
        @patch_path ||= Pathname(HandlebarsAssets::Config.patch_path)
      end

      def runtime_source
        return @runtime_source if @runtime_source
        @runtime_source = runtime_path.read
        HandlebarsAssets::Config.patch_files.each do |patch_file|
          @runtime_source += Rails.application.assets[patch_file].body
        end
        @runtime_source
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
