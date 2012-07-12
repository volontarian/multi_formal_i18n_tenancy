require 'spec_helper'

# ruby gems
require 'i18n'

require 'multi_formal_i18n_tenancy'

describe MultiFormalI18nTenancy::Backend do
  before :all do
    I18n.backend = MultiFormalI18nTenancy::Backend.new
    I18n.load_path = [
      File.expand_path('../../../fixtures/de.yml', __FILE__),
      File.expand_path('../../../fixtures/de_formal.yml', __FILE__),
      File.expand_path('../../../fixtures/tenants/your_tenant_name/your_tenant_name_de.yml', __FILE__),
      File.expand_path('../../../fixtures/tenants/your_tenant_name/your_tenant_name_de_formal.yml', __FILE__)
    ]
  end
  
  describe '.translate' do
    context 'default' do
      context 'formal translation available' do
        it 'returns the formal translation' do
          I18n.locale = :de
          I18n.t('formal_available').should == 'Du'
          I18n.locale = :de_formal
          I18n.t('formal_available').should == 'Sie'
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
          I18n.locale = :your_tenant_name_de_formal
          I18n.t('formal_available').should == 'Sie auch'
        end
      end
      
      context 'formal translation unavailable' do
        it 'inerits the informal locales from :de and :your_tenant_name_de' do
          I18n.locale = :your_tenant_name_de_formal
          I18n.t('formal_unavailable').should == 'Du'
          I18n.t('formal_unavailable_again').should == 'Du auch wieder'
        end
      end
    end
  end
end
