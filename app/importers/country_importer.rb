# encoding: UTF-8
require 'csv'

class CountryImporter < Importer

  def import
    puts 'CountryImporter#import'

    COUNTRY_CSV.each do |line|
      name = line[0]
      iso3 = line[1].downcase

      country = Country.where(iso3: iso3).first_or_initialize
      country.name = name
      puts "Update/create country #{country.inspect}"
      country.save!
    end
  end

  # Returns an array of all pre-defined country groups for client-side processing
  def self.country_groups
    country_groups = []
    GROUPNAMES.each_with_index do |name, index|
      countries = COUNTRY_CSV.select do |line|
        line[index + 2] =~ /x/
      end
      countries = countries.map do |columns|
        columns[1].downcase
      end
      country_groups << {
        title: name,
        countries: countries
      }
    end
    country_groups
  end

# Constants
# ---------

GROUPNAMES = %w(OECD EU Eurozone BRIC)

# x means that the country is part of the groups above
COUNTRY_CSV = CSV.parse(<<-CSV, col_sep: "\t")
Australia	AUS	x
Austria	AUT	x	x	x
Belgium	BEL	x	x	x
Bulgaria	BGR		x
Canada	CAN	x
Croatia	HRV		x
Cyprus	CYP		x	x
Czech Republic	CZE	x	x
Denmark	DNK	x	x
Estonia	EST	x	x	x
Finland	FIN	x	x	x
France	FRA	x	x	x
Germany	DEU	x	x	x
Greece	GRC	x	x	x
Hungary	HUN	x	x
Iceland	ISL	x
Ireland	IRL	x	x	x
Italy	ITA	x	x	x
Japan	JPN	x
Korea	KOR	x
Latvia	LVA		x
Lithuania	LTU		x
Luxembourg	LUX		x	x
Malta	MLT		x	x
Netherlands	NLD	x	x	x
New Zealand	NZL	x
Norway	NOR	x
Poland	POL	x	x
Portugal	PRT	x	x	x
Romania	ROU		x
Slovakia	SVK	x	x	x
Slovenia	SVN	x	x	x
Spain	ESP	x	x	x
Sweden	SWE	x	x
Switzerland	CHE	x
United Kingdom	GBR	x	x
United States	USA	x
Argentina	ARG
Brazil	BRA				x
Chile	CHL	x
China	CHN				x
India	IND				x
Israel	ISR	x
Mexico	MEX	x
Russian Federation	RUS				x
South Africa	ZAF
Turkey	TUR	x
CSV

end