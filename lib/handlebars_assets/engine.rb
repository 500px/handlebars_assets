require 'action_view/template/handlers/handlebars'

module HandlebarsAssets
  class Engine < ::Rails::Engine
    initializer "sprockets.handlebars", :after => "sprockets.environment", :group => :all do |app|
      next unless app.assets
      app.assets.register_engine('.hbs', TiltHandlebars)
      app.assets.register_engine('.handlebars', TiltHandlebars)
      app.assets.register_engine('.hamlbars', TiltHandlebars) if HandlebarsAssets::Config.haml_available?
      app.assets.register_engine('.slimbars', TiltHandlebars) if HandlebarsAssets::Config.slim_available?
    end

    initializer "handlebars.register_template_handler" do
      ActiveSupport.on_load(:action_view) do
        ActionView::Template.register_template_handler(:hbs, ActionView::Template::Handlers::Handlebars)
        ActionView::Template.register_template_handler(:handlebars, ActionView::Template::Handlers::Handlebars)
        ActionView::Template.register_template_handler(:hamlbars, ActionView::Template::Handlers::Handlebars) if HandlebarsAssets::Config.haml_available?
        ActionView::Template.register_template_handler(:slimbars, ActionView::Template::Handlers::Handlebars) if HandlebarsAssets::Config.slim_available?
      end
    end

  end
end
