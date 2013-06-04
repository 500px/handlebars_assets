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
        @context ||= ExecJS.compile(apply_patches_to_source)
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
        source
      end

      def source
        @source ||= path.read
      end

      def patch_path
        @patch_path ||= Pathname(HandlebarsAssets::Config.patch_path)
      end

      def patch_source(patch_file)
        Rails.application.assets[patch_file].body
      end

      def runtime_source
        @runtime = runtime_path.read
        HandlebarsAssets::Config.patch_files.each do |patch_file|
          @runtime << "\n;"
          @runtime << Rails.application.assets[patch_file].body
          @runtime << "\n;"
        end
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
