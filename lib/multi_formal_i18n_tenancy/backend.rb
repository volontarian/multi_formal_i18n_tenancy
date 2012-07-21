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
    
    @filenames.each { |filename| load_file(filename) }
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
  
  protected
  
  # Looks up a translation from the translations hash. Returns nil if
  # eiher key is nil, or locale, scope or key do not exist as a key in the
  # nested translations hash. Splits keys or scopes containing dots
  # into multiple keys, i.e. <tt>currency.format</tt> is regarded the same as
  # <tt>%w(currency format)</tt>.
  def lookup(locale, key, scope = [], options = {})
    init_translations unless initialized?
    
    # only formal address: [:de, :de_formal]
    # only multi tenancy: [:de, :tenant_name_de]
    # formal address & multi tenancy: [:de, :tenant_name_de, :de_formal, :tenant_name_de_formal]
    
    locales = []
    
    base_locale = locale.to_s.gsub(FORMAL_LOCALE_PATTERN, '')
    
    tenant = tenant_from_locale?(locale)
    base_locale.gsub!(/^#{tenant}_/, '') if tenant
    
    locales << base_locale.to_sym 
    
    if locale.to_s.match(FORMAL_LOCALE_PATTERN) && tenant && locale.to_s.match(/^#{tenant}_/)
      locales << locale.to_s.gsub(FORMAL_LOCALE_PATTERN, '').to_sym
      locales << locale.to_s.gsub(/^#{tenant}_/, '').to_sym
    end
    
    locales << locale unless locales.include?(locale)
    
    entry, last_entry = nil, nil
    
    locales.each do |locale|
      keys = I18n.normalize_keys(locale, key, scope, options[:separator])
  
      entry = keys.inject(translations) do |result, _key|
        _key = _key.to_sym
        
        unless result.is_a?(Hash) && result.has_key?(_key)
          nil
        else
          result = result[_key]
          result = resolve(locale, _key, result, options.merge(:scope => nil)) if result.is_a?(Symbol)
          result
        end
      end
      
      if entry.nil?
        entry = last_entry
      else
        last_entry = entry
      end
    end
    
    entry
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