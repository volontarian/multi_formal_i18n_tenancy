class MultiFormalI18nTenancy::Backend < I18n::Backend::Simple
  FORMAL_FILENAME_PATTERN = /_formal\.[a-zA-Z]+$/
  FORMAL_LOCALE_PATTERN = /_formal$/

  TENANT_FILENAME_PATTERN = /tenants/
  TENANT_LOCALE_PATTERN = /tenants$/

  attr_accessor :filenames

  # Accepts a list of paths to translation files. Loads translations from
  # plain Ruby (*.rb) or YAML files (*.yml). See #load_rb and #load_yml
  # for details.
  def load_translations(*filenames)
    filenames = I18n.load_path if filenames.empty?
    
    @filenames = filenames.flatten
    
    [
      # locale file groups order (ancestor chain)
      #
      # a) de > de_formal > your_enterprise_name_de > your_enterprise_name_de_formal
      # b) de > your_enterprise_name_de
      
      # de
      ->(f) { !f.match(FORMAL_FILENAME_PATTERN) && !f.match(TENANT_FILENAME_PATTERN) },
      # de > your_enterprise_name_de
      ->(f) { !f.match(FORMAL_FILENAME_PATTERN) && f.match(TENANT_FILENAME_PATTERN) },
      # de > de_formal
      ->(f) { f.match(FORMAL_FILENAME_PATTERN) && !f.match(TENANT_FILENAME_PATTERN) },
      # de > de_formal > your_enterprise_name_de > your_enterprise_name_de_formal
      ->(f) { f.match(FORMAL_FILENAME_PATTERN) && f.match(TENANT_FILENAME_PATTERN) }
    ].each do |filename_filter|
      filenames.flatten.select{|f| filename_filter.call(f) }.each { |filename| load_file(filename) }
    end
    
    @filenames = [] # free memory
  end
      
  # Stores translations for the given locale in memory.
  # This uses a deep merge for the translations hash, so existing
  # translations will be overwritten by new ones only at the deepest
  # level of the hash.
  def store_translations(locale, data, options = {})
    locale = locale.to_sym
    
    # the has_key check assures that the inheritance will be performed for the first locale file
    if (locale.to_s.match(FORMAL_LOCALE_PATTERN) || tenant_from_locale?(locale)) && !translations.has_key?(locale)
      # inherit keys from base locale file
      base_locale = locale.to_s
      tenant = tenant_from_locale?(locale)
      
      if tenant && locale.to_s.match(FORMAL_LOCALE_PATTERN)
        # de > de_formal
        base_locale = locale.to_s.gsub(/^#{tenant}_/, '')
        translations[locale] = (translations[base_locale.to_sym] || {}).clone
        
        # de_formal > your_enterprise_name_de
        base_locale = locale.to_s.gsub(FORMAL_LOCALE_PATTERN, '') 
        base_translations = (translations[base_locale.to_sym] || {}).clone.deep_symbolize_keys # deep_symbolize_keys?
        translations[locale].deep_merge!(base_translations)
      elsif tenant
        base_locale.gsub!(/^#{tenant}_/, '')
      else
        base_locale.gsub!(FORMAL_LOCALE_PATTERN, '') 
      end
       
      translations[locale] = (translations[base_locale.to_sym] || {}).clone
    else
      translations[locale] ||= {}
    end
    
    data = data.deep_symbolize_keys
    
    translations[locale].deep_merge!(data)
  end
  
  private
  
  def tenant_from_locale?(locale)
    tenant = locale.to_s.gsub(FORMAL_LOCALE_PATTERN, '').split('_')
    
    if tenant.length > 2
      tenant.pop # pop languages like de
      tenant = tenant.join('_')
    else
      tenant = nil
    end
    
    tenant && @filenames.select{|f| f.match("/tenants/#{tenant}/")}.any? ? tenant : nil
  end
end