require 'spec_helper'

describe CountriesController do
  let(:basic_request) do
    {
      'countries' => [
        {'type' => "Country", "iso3" => 'deu'},
        {'type' => "Country", "iso3" => 'aut'},
        {'type' => "Country", "iso3" => 'fra'},
        {'type' => "CountryGroup", 'title' => "BeNeLux", 'countries' => [
          {'type' => "Country", "iso3" => 'bel'},
          {'type' => "Country", "iso3" => 'nld'}
        ]}
      ],
      'year' => 2008,
      'type_with_unit' => ['debt', 'bln_current_dollars']
    }
  end

  let(:country_array){mock "CountryArray"}
  let(:twu){mock("TypeWithUnit",
      :set_data_type_and_unit => nil,
      :set_indicator_type_and_unit => nil)}

  before do
    TypeWithUnit.stub!(:new).and_return(twu)

    controller.stub(:sortrequest){
      sortrequest['countries'].stub!(:map).and_return(country_array)
      sortrequest
    }
  end

  describe "receiving data request" do

    let(:sortrequest) do
      basic_request.merge('type' => 'data', 'direction' => 'in')
    end

    it "should sort" do
      CountrySorter.should_receive(:sort_by_data_type).with(country_array, 2008, twu, :in)
      post :sort, :sortrequest => sortrequest.to_json
    end

  end

  describe "receiving indicators request" do

    let(:sortrequest) do
      basic_request.merge('type' => 'indicator')
    end

    it "should sort" do
      CountrySorter.should_receive(:sort_by_indicator_type).with(country_array, 2008, twu)
      post :sort, :sortrequest => sortrequest.to_json
    end

  end

end