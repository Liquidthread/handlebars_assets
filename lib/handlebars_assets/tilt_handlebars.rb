require 'tilt'

module HandlebarsAssets
  class TiltHandlebars < Tilt::Template
    def self.default_mime_type
      'application/javascript'
    end

    def evaluate(scope, locals, &block)
      name = basename(scope.logical_path)
      relative_path = scope.logical_path.gsub(/^templates\/(.*)$/i, "\\1")
      handlebars = ::Haml::Engine.new(data, locals).render.gsub(/\n/m, "").strip
      compiled_hbs = Handlebars.precompile(handlebars)

      if name.start_with?('_')
        partial_name = relative_path.gsub(/\//, '_').gsub(/__/, '_').dump
        <<-PARTIAL
          (function() {
            Handlebars.registerPartial(#{partial_name}, Handlebars.template(#{compiled_hbs}));
          }).call(this);
        PARTIAL
      else
        template_name = relative_path.dump
        <<-TEMPLATE
          (function() {
            this.HandlebarsTemplates || (this.HandlebarsTemplates = {});
            this.HandlebarsTemplates[#{template_name}] = Handlebars.template(#{compiled_hbs});
            return HandlebarsTemplates[#{template_name}];
          }).call(this);
        TEMPLATE
      end
    end

    protected

    def basename(path)
      path.gsub(%r{.*/}, '')
    end

    def prepare; end
  end
end
