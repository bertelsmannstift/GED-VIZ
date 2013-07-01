require 'spec_helper'

describe IndicatorValue do
  subject {IndicatorValue.new(unit: unit, tendency: 0)}
  context "with a unit" do
    let(:unit){Unit.create!(representation: 'proportional')}

    it "should accept and return decimal values" do
      subject.value = 12.3
      subject.value.should == 12.3
    end

    it "should store and retrieve the value correctly from the database" do
      subject.value = 12.3
      subject.save!
      loaded = IndicatorValue.find subject.id
      loaded.value.should == 12.3
    end
  end
end