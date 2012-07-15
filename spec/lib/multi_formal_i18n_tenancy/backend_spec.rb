require 'spec_helper'

# ruby gems
require 'i18n'

require 'multi_formal_i18n_tenancy'

describe MultiFormalI18nTenancy::Backend do
  before :all do
    I18n.default_locale = :de
    I18n.locale = I18n.default_locale
  end
  
  describe '#load_translations' do
    include_context :all_locale_file_constellations
    
    before :all do
      I18n.backend = MultiFormalI18nTenancy::Backend.new
    end
    
    context 'default' do
      context 'formal translation available' do
        it 'returns the formal translation' do
          I18n.locale = :de
          I18n.t('formal_available').should == 'Du'
          I18n.t('de_formal_formal_available').should == 'Du'
          I18n.locale = :de_formal
          I18n.t('formal_available').should == 'Sie'
          I18n.t('de_formal_formal_available').should == 'Sie'
        end
      end
      
      context 'formal translation unavailable' do
        it 'inerits the informal locales from :de' do
          I18n.locale = :de_formal
          I18n.t('formal_unavailable').should == 'Du'
        end
      end
    end
    
    context 'tenant-specific' do
      context 'formal translation available' do
        it 'returns the formal translation' do
          I18n.locale = :your_tenant_name_de
          I18n.t('formal_available').should == 'Du auch'
          I18n.t('de_formal_formal_available').should == 'Du'
          I18n.locale = :your_tenant_name_de_formal
          I18n.t('formal_available').should == 'Sie auch'
          I18n.t('de_formal_formal_available').should == 'Sie'
        end
      end
      
      context 'formal translation unavailable' do
        it 'inerits the informal locales from :de and :your_tenant_name_de' do
          I18n.locale = :your_tenant_name_de_formal
          I18n.t('formal_unavailable').should == 'Du'
          I18n.t('formal_unavailable_again').should == 'Du auch wieder'
        end
      end
      
      context 'formal translation available for locale without base locale' do
        it 'inits the locale without inheritation of unavailable base locale' do
          I18n.locale = :another_tenant_name_fr_formal
          I18n.t('formal_available').should == 'jamais vous'
        end
      end
    end
    
    context 'locale files with more than 1 dot' do
      it 'principally works' do
        I18n.locale = :de
        I18n.t('devise.example').should == 'Dein Beispiel' 
        I18n.locale = :de_formal
        I18n.t('devise.example').should == 'Ihr Beispiel'
        I18n.locale = :your_tenant_name_de_formal
        I18n.t('devise.informal_example').should == 'Dein anderes Beispiel' # devise.de.yml
        I18n.t('devise.examples').should == 'Ihre Beispiele' # devise.de_formal.yml
        I18n.t('devise.example').should == 'Ihr formelles Beispiel' # tenants/your_tenant_name/devise.your_tenant_name_de_formal.yml
      end
    end
  end
  
  describe '.available_locale' do
    context 'any locale' do
      before :all do
        I18n.load_path = [
          File.expand_path('../../../fixtures/de.yml', __FILE__),
          File.expand_path('../../../fixtures/en.yml', __FILE__)
        ]
      end
      
      # .available_locale any locale principally works
      it 'principally works' do
        I18n.backend = MultiFormalI18nTenancy::Backend.new
        
        [
          [{}, :de], 
          [{base_locale: :en}, :en], 
          [{base_locale: :unavailable}, :de],
          [{tenant: 'Your Tenant Name'}, :de],
          [{formal: true, tenant: 'Your Tenant Name'}, :de],
          [{formal: true, tenant: 'Unavailable Tenant Name'}, :de]
        ].each do |variant|
          actual = I18n.backend.available_locale(variant.first)
          actual.should(
            be(variant.last), 
            "input #{variant.first.inspect} should result in the output: #{variant.last.inspect} but got #{actual.inspect}"
          )
        end
      end
    end
    
    context 'any formal locale' do
      before :all do
        I18n.load_path = [
          File.expand_path('../../../fixtures/de.yml', __FILE__),
          File.expand_path('../../../fixtures/de_formal.yml', __FILE__)
        ]
      end
      
      it 'principally works' do
        I18n.backend = MultiFormalI18nTenancy::Backend.new
        
        [
          [{formal: true}, :de_formal], 
          [{formal: true, tenant: 'Your Tenant Name'}, :de_formal]
        ].each do |variant|
          actual = I18n.backend.available_locale(variant.first)
          actual.should(
            be(variant.last), 
            "input #{variant.first.inspect} should result in the output: #{variant.last.inspect} but got #{actual.inspect}"
          )
        end
      end
    end
    
    context 'any formal locale plus tenant specific locale' do
      before :all do
        I18n.load_path = [
          File.expand_path('../../../fixtures/de.yml', __FILE__),
          File.expand_path('../../../fixtures/de_formal.yml', __FILE__),
          File.expand_path('../../../fixtures/tenants/your_tenant_name/your_tenant_name_de.yml', __FILE__),
          File.expand_path('../../../fixtures/tenants/your_tenant_name/your_tenant_name_en.yml', __FILE__)
        ]
      end
      
      it 'principally works' do
        I18n.backend = MultiFormalI18nTenancy::Backend.new
        
        [
          [{formal: true}, :de_formal], 
          # should be :your_tenant_name_de_formal even though there is no :your_tenant_name_de_formal file 
          # but the base file :de_formal to inherit from
          [{formal: true, tenant: 'Your Tenant Name'}, :your_tenant_name_de_formal],
          [{base_locale: :en, formal: true, tenant: 'Your Tenant Name'}, :your_tenant_name_en]
        ].each do |variant|
          actual = I18n.backend.available_locale(variant.first)
          actual.should(
            be(variant.last), 
            "input #{variant.first.inspect} should result in the output: #{variant.last.inspect} but got #{actual.inspect}"
          )
        end
      end
    end
    
    context 'any formal tenant-specific locale' do
      include_context :all_locale_file_constellations
      
      it 'principally works' do
        I18n.backend = MultiFormalI18nTenancy::Backend.new
      end
    end 
    
    context 'tenant has special locale without an equivalent base locale' do
      before :all do
        I18n.load_path = [
          File.expand_path('../../../fixtures/tenants/your_tenant_name/your_tenant_name_de_formal.yml', __FILE__)
        ]
      end
      
      it 'principally works' do
        I18n.backend = MultiFormalI18nTenancy::Backend.new
        
        [
          [{base_locale: :de, formal: true, tenant: 'Your Tenant Name'}, :your_tenant_name_de_formal]
        ].each do |variant|
          actual = I18n.backend.available_locale(variant.first)
          actual.should(
            be(variant.last), 
            "input #{variant.first.inspect} should result in the output: #{variant.last.inspect} but got #{actual.inspect}"
          )
        end
      end
    end
  end
end
