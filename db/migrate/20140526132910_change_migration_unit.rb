class ChangeMigrationUnit < ActiveRecord::Migration
  def change
    persons_unit = Unit.where(key: 'persons').first

    Presentation.all.each do |p|
      found = false
      p.keyframes.each do |k|
        twu = k.data_type_with_unit
        if twu.type.key == 'migration' && twu.unit.key == 'tsd_persons'
          found = true
          twu.unit = persons_unit
        end
      end
      if found
        puts "Migrate presentation #{p.id}"
        p.save
      end
    end
  end
end
