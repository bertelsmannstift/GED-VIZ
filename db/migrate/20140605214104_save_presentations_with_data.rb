class SavePresentationsWithData < ActiveRecord::Migration
  def up
    Presentation.find_each(batch_size: 100) do |presentation|
     print "Saving presentation #{presentation.id}… "
     STDOUT.flush
     presentation.save_from_scratch
     puts 'Done.'
    end
    puts 'All done.'
  end

  def down
  end
end
