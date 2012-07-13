require 'active_support/core_ext/string/inflections'

module MultiFormalI18nTenancy
end

require 'multi_formal_i18n_tenancy/engine' if defined? Rails::Engine

require 'multi_formal_i18n_tenancy/backend'
