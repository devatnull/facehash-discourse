# frozen_string_literal: true

module ::FacehashDiscourse
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace FacehashDiscourse
    config.autoload_paths << File.join(config.root, "lib")
  end
end

