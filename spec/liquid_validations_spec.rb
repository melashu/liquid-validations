require_relative './spec_helper'
class Mixin < ActiveRecord::Base
end

describe LiquidValidations do
  it 'should provide the validates_liquid_of method to ActiveRecord subclasses' do
    Mixin.must_respond_to(:validates_liquid_of)
  end

  it 'should provide the validates_presence_of_liquid_variable method to ActiveRecord subclasses' do
    Mixin.must_respond_to(:validates_presence_of_liquid_variable)
  end

  it 'should provide the validates_presence_of_liquid_tag method to ActiveRecord subclasses' do
    Mixin.must_respond_to(:validates_presence_of_liquid_tag)
  end



  describe '.validates_liquid_of' do
    before do
      Mixin.instance_eval do
        validates_liquid_of :content
      end

      @mixin = Mixin.new
      @mixin.errors.clear
    end

    [ ' {{ Bad liquid ',
      ' {% Bad liquid ',
      '{% for %}{% endfor' ].each do |bad_liquid|
      it "the record should be invalid when there is a liquid parsing error for #{ bad_liquid }" do
        @mixin.content = bad_liquid
        @mixin.valid?.must_equal false
      end
    end

    it 'should include the errors in the errors object' do
      @mixin.content = '{{ unclosed variable '
      @mixin.valid?
      @mixin.errors.full_messages.any? { |e| e == "Variable '{{' was not properly closed in your content" }.must_equal true
    end
  end

  describe '.validates_presence_of_liquid_variable' do
    before do
      Mixin.instance_eval do
        validates_presence_of_liquid_variable :content, :variable => 'josh_is_awesome'
      end
      @mixin = Mixin.new
    end

    it 'must be configured properly' do
      proc { Mixin.instance_eval { validates_presence_of_liquid_variable :content } }.must_raise ArgumentError
    end

    it 'the record should be invalid when the specified variable is not present' do
      @mixin.content = '{{ josh_is_not_awesome }}'
      @mixin.valid?.must_equal false
    end

    it 'should include the errors in the errors object' do
      @mixin.content = '{{ josh_is_not_awesome }}'
      @mixin.valid?
      @mixin.errors.full_messages.any? { |e| e == "You must include {{ josh_is_awesome }} in your content" }.must_equal true
    end
  end

  describe '.validates_presence_of_liquid_tag' do
     before do
      Mixin.instance_eval do
        validates_presence_of_liquid_tag :content, :filter => 'josh_is_awesome', max: 2
      end
      @mixin = Mixin.new    
    end

    it 'must be configured properly' do
      proc { Mixin.instance_eval { validates_presence_of_liquid_tag :content, filter: 'josh_is_awesome'} }.must_raise ArgumentError
    end

    it 'the record should be invalid when the specified filter and max is not present' do
      @mixin.content = 'josh_is_awesome'
      @mixin.valid?.must_equal false
    end

    it 'should include the errors in the errors object' do
      @mixin.content = 'josh_is_awesome'
      @mixin.valid?
      @mixin.errors.full_messages.any? { |e| e == "You must supply {% josh_is_awesome %} in your content"}.must_equal true
    end

   
    it 'must be valid when include filter' do
      @mixin.content = '{% josh_is_awesome %} '
      @mixin.valid?
      @mixin.errors.full_messages.any? { |e| e == "You must supply {% josh_is_awesome %} in your content"}.must_equal false
    end

    it 'must be valid when filter is less than or equal max count' do
      @mixin.content = '{% josh_is_awesome %} {% josh_is_awesome %}'
      @mixin.valid?
      @mixin.errors.full_messages.any? { |e| e == "You must supply {% josh_is_awesome %} in your content"}.must_equal false
    end

    it 'must be invalid when filter is greater than max count' do
      @mixin.content = '{% josh_is_awesome %} {% josh_is_awesome %} {% josh_is_awesome %}'
      @mixin.valid?
      @mixin.errors.full_messages.any? { |e| e == "content must not have more than max filters 2"}.must_equal true
    end

    it 'must be valid when using more complex filter' do
      @mixin.content = "{% josh_is_awesome foobar, data-required='true' %}"
      @mixin.valid?
      @mixin.errors.full_messages.any? { |e| e == "You must supply {% josh_is_awesome %} in your content"}.must_equal false
    end

    it 'must be invalid when using more complex filter' do
      @mixin.content = "{% josh_is_awesome foobar, data-required='true' %}"
      @mixin.valid?
      @mixin.errors.full_messages.any? { |e| e == "You must supply {% josh_is_awesome %} in your content"}.must_equal false
    end

    it 'must be invalid when using filter like { josh_is_awesome }' do
      @mixin.content = "{ josh_is_awesome }"
      @mixin.valid?
      @mixin.errors.full_messages.any? { |e| e == "You must supply {% josh_is_awesome %} in your content"}.must_equal true
    end

    it 'must be invalid when using filter like {% josh_is_awesome }' do
      @mixin.content = "{% josh_is_awesome }"
      @mixin.valid?
      @mixin.errors.full_messages.any? { |e| e == "You must supply {% josh_is_awesome %} in your content"}.must_equal true
    end

    it 'must be invalid when using filter like { josh_is_awesome %}' do
      @mixin.content = "{ josh_is_awesome %}"
      @mixin.valid?
      @mixin.errors.full_messages.any? { |e| e == "You must supply {% josh_is_awesome %} in your content"}.must_equal true
    end

    it 'must be invalid when using filter like {%% josh_is_awesome %%}' do
      @mixin.content = "{%% josh_is_awesome %%}"
      @mixin.valid?
      @mixin.errors.full_messages.any? { |e| e == "You must supply {% josh_is_awesome %} in your content"}.must_equal true
    end

    it 'must be invalid when using filter like %{ josh_is_awesome }%' do
      @mixin.content = "%{ josh_is_awesome }%"
      @mixin.valid?
      @mixin.errors.full_messages.any? { |e| e == "You must supply {% josh_is_awesome %} in your content"}.must_equal true
    end

    it 'must be invalid when using filter like empty content' do
      @mixin.valid?
      @mixin.errors.full_messages.any? { |e| e == "You must supply {% josh_is_awesome %} in your content"}.must_equal true
    end

    it 'must be invalid when filter is greater than max count' do
      @mixin.content = '{% josh_is_awesome %} {% josh_is_awesome %} {% josh_is_'
      @mixin.valid?
      @mixin.errors.full_messages.any? { |e| e == "content must not have more than max filters 2"}.must_equal false
    end

  end
  
end
