class FixCountryIsoCodes < ActiveRecord::Migration

  ISO3_MAP = {
    # Romania
    'rom' => 'rou'
  }

  def up
    migrate_presentations
    migrate_countries
    puts 'All done.'
  end

  def down
  end

  private

  def migrate_presentations
    Presentation.find_each(batch_size: 50) do |presentation|
      puts "Changing presentation #{presentation.id}… "
      migrate_presentation(presentation)
      STDOUT.flush
    end
  end

  def migrate_presentation(presentation)
    presentation_changed = false
    presentation.keyframes.each do |keyframe|
      keyframe.countries.each do |country_or_group|
        if country_or_group.is_a?(CountryGroup)
          countries = country_or_group.countries
        else
          countries = [country_or_group]
        end
        countries.each do |country|
          old_iso3 = country.iso3
          new_iso3 = ISO3_MAP[old_iso3]
          if new_iso3
            puts "Change #{old_iso3} > #{new_iso3}"
            country.iso3 = new_iso3
            presentation_changed = true
          end
        end
      end
    end
    presentation.save_from_scratch if presentation_changed
  end

  def migrate_countries
    ISO3_MAP.each do |old_iso3, new_iso3|
      puts "Change country #{old_iso3} to #{new_iso3}"
      country = Country.find_by_iso3(old_iso3)
      next unless country
      country.iso3 = new_iso3
      country.save
    end
  end

end
