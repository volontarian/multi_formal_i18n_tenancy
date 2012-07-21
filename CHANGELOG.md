## multi_formal_i18n_tenancy (unreleased) ##

## multi_formal_i18n_tenancy 0.0.5 (July 21, 2012) ##

*   avoid redundant storage of translations and inherit translations through overriding lookup instead of store_translations method

    *Mathias Gawlista*

## multi_formal_i18n_tenancy 0.0.4 (July 16, 2012) ##

*   Fixes a bug at formal address feature for the following missing constellation / test example

      de:
        key: 'Du'
      
      de_formal:
        key: 'Sie'
     
      I18n.locale = :de
      I18n.t('de_formal').should == 'Du' # success
      I18n.locale = :de_formal
      I18n.t('de_formal').should == 'Sie' # success
     
      I18n.locale = :tenant_name_de_formal
      
      # failure:
      # expected: "Sie"
      # got: "Du"
      I18n.t('de_formal').should == 'Sie'

    *Mathias Gawlista*

## multi_formal_i18n_tenancy 0.0.3 (July 13, 2012) ##

*   Adds new instance method available_locale to return the most compatible locale for formal address and / or multi tenancy inheritance setting to be used at locale switch through controller's before filter and / or optional config initializer.
    
    *Mathias Gawlista*
    
*   Adds support for locale files with more than 1 dot like devise.de.yml.

    *Mathias Gawlista*

## multi_formal_i18n_tenancy 0.0.2 (July 12, 2012) ##

*   Initialize gem module first to avoid "uninitialized constant" exception when bundling the gem without local path option.

    *Mathias Gawlista*

## multi_formal_i18n_tenancy 0.0.1 (July 11, 2012) ##

*   initial version

    *Mathias Gawlista*
