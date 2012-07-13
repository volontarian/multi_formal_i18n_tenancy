shared_context :all_locale_file_constellations do
  before :all do
    I18n.load_path = [
      File.expand_path('../../../fixtures/de.yml', __FILE__),
      File.expand_path('../../../fixtures/de_formal.yml', __FILE__),
      File.expand_path('../../../fixtures/tenants/your_tenant_name/your_tenant_name_de.yml', __FILE__),
      File.expand_path('../../../fixtures/tenants/your_tenant_name/your_tenant_name_de_formal.yml', __FILE__),
      File.expand_path('../../../fixtures/tenants/another_tenant_name/another_tenant_name_fr_formal.yml', __FILE__),
      File.expand_path('../../../fixtures/devise.de.yml', __FILE__),
      File.expand_path('../../../fixtures/devise.de_formal.yml', __FILE__),
      File.expand_path('../../../fixtures/tenants/your_tenant_name/devise.your_tenant_name_de_formal.yml', __FILE__),
    ]
  end
end
