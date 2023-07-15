require 'liquid-validations/version'

module LiquidValidations
  def validates_liquid_of(*attr_names)
    configuration = { :message => I18n.translate('activerecord.errors.messages')[:invalid] }
    configuration.update(attr_names.extract_options!)

    validates_each attr_names, configuration do |record, attr_name, value|
      errors = []

      begin
        template = Liquid::Template.parse(value.to_s)
        errors  += template.errors
      rescue Exception => e
        errors << e.message
      end

      for error in errors
        record.errors.add(:base, friendly_liquid_error(error) + " in your #{ friendly_attr_name(attr_name) }")
      end
    end
  end

  def validates_presence_of_liquid_variable(*attr_names)
    configuration = { :message => I18n.translate('activerecord.errors.messages')[:invalid], :variable => nil, :container => nil }
    configuration.update(attr_names.extract_options!)

    raise(ArgumentError, "You must supply a variable to check for") if configuration[:variable].blank?

    validates_each attr_names, configuration do |record, attr_name, value|
      value         = value.to_s
      variable      = configuration[:variable].to_s
      variable_re   = /\{\{\s*#{ variable }( .*)?\}\}/
      container     = configuration[:container].to_s
      container_re  = /<\s*#{ container }.*>.*#{ variable_re }.*<\/\s*#{ container }\s*>/im

      if container.blank? && !(value =~ variable_re)
        record.errors.add(:base, "You must include {{ #{ variable } }} in your #{ friendly_attr_name(attr_name) }")
      elsif !container.blank? && !(value =~ container_re)
        record.errors.add(:base, "You must include {{ #{ variable } }} inside the <#{ container }> tag of your #{ friendly_attr_name(attr_name) }")
      end
    end
  end

  def validates_liquid_tag(*attr_names)
    configuration = { :message => I18n.translate('activerecord.errors.messages')[:invalid], tag: nil, max: nil, presence: true }
    configuration.update(attr_names.extract_options!)
    
    raise(ArgumentError, 'You must supply a tag and max to check for ') if (configuration[:tag].blank? || configuration[:max].blank? ) && configuration[:presence] 
    validates_each attr_names, configuration do |record, attr_name, value|
      value    = value.to_s
      max      = configuration[:max]
      presence = configuration[:presence]
      tag   = configuration[:tag].to_s
      tag_r = /{%\s+#{tag}\s+(.*?)%}/
      if !(value =~ tag_r)
        record.errors.add(:base, "You must supply {% #{tag} %} in your #{ friendly_attr_name(attr_name) }")
      elsif presence && (value.scan(tag_r).size > max)
       record.errors.add(:base, "#{friendly_attr_name(attr_name)} must not have more than #{max} {% #{tag} %}")
      elsif !presence && (value.scan(tag_r).size > max)
        record.errors.add(:base, "#{friendly_attr_name(attr_name)} must not have more than #{max} {% #{tag} %}") 
      end
    end
    
  end

  private

  def friendly_attr_name(attr_name)
    attr_name.to_s.humanize.downcase
  end

  def friendly_liquid_error(error)
    error.gsub(/liquid/i, '').gsub(/terminated with regexp:.+/, 'closed')
  end
end

ActiveRecord::Base.extend(LiquidValidations)
