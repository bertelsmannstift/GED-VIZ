require 'rails_helper'

describe Presentation do

  # Disable caching of DataValue / IndicatorValue
  Aggregator.cache_enabled = false

  # Disable caching of Presentation#data_changed?
  Presentation.changed_cache_enabled = false

  let(:year) { 2010 }
  let(:import) { DataType.find_by_key('import') }
  let(:bln_current_dollars) { Unit.find_by_key('bln_current_dollars') }
  let(:gdp) { IndicatorType.find_by_key('gdp') }
  let(:bln_real_dollars) { Unit.find_by_key('bln_real_dollars') }
  let(:deu) { Country.find_by_iso3('deu') }
  let(:usa) { Country.find_by_iso3('usa') }

  subject do
    Presentation.new.tap do |p|
      k = Keyframe.new
      k.title = 'Test'
      k.year = year
      k.countries = [deu, usa]
      k.set_data_type_with_unit(import, bln_current_dollars)
      k.add_indicator_type_with_unit(gdp, bln_real_dollars)
      p.keyframes << k
    end
  end

  let(:as_json) { subject.as_json() }
  let(:json_data_changed) { as_json[:data_changed] }

  context 'new presentation' do
    it 'should not have changed' do
      subject.data_changed?.should be false
      json_data_changed.should be false
    end
  end

  context 'saved presentation' do

    context 'same data' do
      it 'should not have changed' do
        subject.save
        subject.data_changed?.should be false
        json_data_changed.should be false
      end
    end

    context 'different bilateral data' do
      let(:data_value) do
        DataValue.where(
          data_type_id: import.id, unit_id: bln_current_dollars.id,
          country_from_id: deu.id, country_to_id: usa.id,
          year: year
        ).first
      end

      it 'should have changed' do
        subject.save
        #puts "saved #{subject.object_id} #{subject.id}"

        # Change the data
        data_value.value += 200
        data_value.save

        subject.data_changed?.should be true
        json_data_changed.should be true
      end
    end

    context 'different unilateral data' do
      let(:indicator_value) do
        IndicatorValue.where(
          indicator_type_id: gdp.id, unit_id: bln_real_dollars.id,
          country_id: usa.id,
          year: year
        ).first
      end

      it 'should have changed' do
        subject.save
        puts "saved #{subject.object_id} #{subject.id}"

        # Change the data
        indicator_value.value += 200
        indicator_value.save

        subject.data_changed?.should be true
        json_data_changed.should be true
      end
    end
  end

end