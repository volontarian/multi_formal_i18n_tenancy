module RailsInfo
  class Engine < ::Rails::Engine  
    config.before_initialize do |app|
      I18n.backend = MultiFormalI18nTenancy::Backend.new
    end
  end
end
