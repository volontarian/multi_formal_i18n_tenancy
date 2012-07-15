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
        base_translations = (translations[base_locale.to_sym] || {}).clone.deep_symbolize_keys
        
        translations[locale] = base_translations.deep_merge(translations[locale])
      elsif tenant
        base_locale.gsub!(/^#{tenant}_/, '')
      else
        base_locale.gsub!(FORMAL_LOCALE_PATTERN, '') 
      end
       
      unless tenant && locale.to_s.match(FORMAL_LOCALE_PATTERN)
        translations[locale] = (translations[base_locale.to_sym] || {}).clone
      end
    else
      translations[locale] ||= {}
    end
    
    data = data.deep_symbolize_keys
    
    translations[locale].deep_merge!(data)
  end
  
  def available_locale(options = {})
    options.assert_valid_keys(:base_locale, :formal, :tenant) if options.respond_to? :assert_valid_keys
    
    base_locale = options[:base_locale] || I18n.default_locale
    formal = options[:formal] || false
    tenant = (options[:tenant] || '').parameterize.gsub('-', '_')
     
    deepest_available_locale = nil
    
    # take last / deepest available locale of possible combinations
    variant_index = -1
    
    [     
      [
        (formal && tenant), 
        [tenant, base_locale, 'formal']
      ],
      [
        formal && tenant && available_locales.include?([tenant, base_locale].join('_').to_sym) &&
        available_locales.include?([base_locale, 'formal'].join('_').to_sym), 
        [tenant, base_locale, 'formal']
      ],    
      [tenant, [tenant, base_locale]],
      [formal, [base_locale, 'formal']],
      [true, [base_locale]], 
    ].each do |variant|
      variant_index += 1
      
      next unless variant[0]

      if available_locales.include?(variant[1].join('_').to_sym) || (variant_index == 1 && [tenant, base_locale, 'formal'] == variant[1])
        deepest_available_locale = variant[1].join('_').to_sym
      end
            
      break if deepest_available_locale
    end
    
    deepest_available_locale || I18n.default_locale
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