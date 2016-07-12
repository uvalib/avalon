namespace :avalon do
  namespace :uva do
    desc "Validates all links to master files and optionally checks fixity when possible"
    task :master_report => :environment do
      if ENV['filename'].nil?
        abort "You must specify a filename for the report.  Example: rake avalon:uva:master_report filename=missing-master-files.txt"
      end
      check_fixity = !ENV['checkfixity'].nil?
      open(ENV['filename'], 'w') do |f|
        Admin::Collection.all.each do |c|
          c.media_object_ids.each do |mo_pid|
            mo = MediaObject.find(mo_pid)
            mo.section_pid.each do | mf_pid |
              mf = MasterFile.find(mf_pid)
              recorded_location = mf.file_location.to_s
              if (!File.file?(recorded_location)) then
                output = "In collection #{c.pid} for media object #{mo.id.to_s}, the master file #{mf.id.to_s} was not found at the path \"#{mf.file_location.to_s}\"!"
                f.puts output
                puts output
              elsif (check_fixity && !mf.file_checksum.to_s.empty?) then
                md5sum = Digest::MD5.file recorded_location
                if (md5sum.to_s != mf.file_checksum.to_s) then
                  output = "In collection #{c.pid} for media object #{mo.id.to_s}, the master file #{mf.id.to_s} at \"#{mf.file_location.to_s}\" has the checksum #{md5sum.to_s} instead of #{mf.file_checksum.to_s}!"
                  f.puts output
                  puts output
                else
                  output = "In collection #{c.pid} for media object #{mo.id.to_s}, the master file #{mf.id.to_s} at \"#{mf.file_location.to_s}\" fixity has been verified (#{md5sum.to_s})!"
                  f.puts output
                  puts output
                end
              else
                output = "In collection #{c.pid} for media object #{mo.id.to_s}, the master file #{mf.id.to_s} at \"#{mf.file_location.to_s}\" was found (no attempt was made to verify fixity)!"
                f.puts output
                puts output
              end
            end
          end
        end
      end
    end

    desc "Fixed up file locations."
    task :fixup => :environment do
        open('master-file-path-update-log.txt', 'w') do |f|
          Admin::Collection.find_each({},{batch_size:10}) do |c|
            c.media_object_ids.each do |mo_pid|
              mo = MediaObject.find(mo_pid)
              mo.section_pid.each do | mf_pid |
                mf = MasterFile.find(mf_pid)
                recorded_location = mf.file_location.to_s
                recorded_filename = recorded_location.split('/')[-1]
                ideal_filename = recorded_filename.gsub(/avalon_\d+-/, '')
                ideal_location = '/lib_content67/AVALON_archive/' + c.id.split(':')[1] + '/' + ideal_filename

                if (File.file?(recorded_location)) then
                  if (ideal_location == recorded_location) then
                    puts "#{ideal_location} is already in the ideal location."
                    f.puts "#{ideal_location} is already in the ideal location."
                  else
                    if (File.file?(ideal_location)) then
                      puts "#{mf.id}: #{ideal_location} already exists... checking md5..."
                      f.puts "#{mf.id}: #{ideal_location} already exists... checking md5..."
                      md5sum = Digest::MD5.file ideal_location
                      if (md5sum.to_s == mf.file_checksum.to_s) then
                        puts "matches!"
                        f.puts "matches!"
                        mf.file_location=ideal_location
                        mf.save!
                        FileUtils.mv recorded_location, recorded_location + ".duplicate", :verbose => true
                      else
                        puts "does not match! #{md5sum} != #{mf.file_checksum.to_s}"
                        f.puts "does not match! #{md5sum} != #{mf.file_checksum.to_s}"
                        ideal_location
                      end
                    else
                      puts "#{mf.id}: #{recorded_location} will be moved to #{ideal_location}"
                      f.puts "#{mf.id}: #{recorded_location} will be moved to #{ideal_location}"
                      FileUtils.mkdir_p File.dirname(ideal_location)
                      FileUtils.mv recorded_location, ideal_location, :verbose => true
                      mf.file_location=ideal_location
                      mf.save!
                    end
                  end
                else
                  puts "#{mf.id}: #{recorded_location} does not exist."
                  f.puts "#{mf.id}: #{recorded_location} does not exist."
                  # Find it in the master file location
                  alternate_location = '/lib_content67/AVALON_archive/' + mf.id.to_s.gsub(/:/, '_') + '-' + recorded_location.split('/')[-1]
                  if File.file?(alternate_location) then

                    if (File.file?(ideal_location)) then
                      puts "#{mf.id}: #{ideal_location} already exists... checking md5..."
                      f.puts "#{mf.id}: #{ideal_location} already exists... checking md5..."
                      md5sum = Digest::MD5.file ideal_location
                      if (md5sum.to_s == mf.file_checksum.to_s) then
                        puts "matches!"
                        f.puts "matches!"
                        mf.file_location=ideal_location
                        mf.save!
                        FileUtils.mv alternate_location, alternate_location + ".duplicate", :verbose => true
                      else
                        puts "does not match! #{md5sum} != #{mf.file_checksum.to_s}"
                        f.puts "does not match! #{md5sum} != #{mf.file_checksum.to_s}"
                        ideal_location
                      end
                    else
                      puts "#{mf.id}: #{alternate_location} will be moved to #{ideal_location}"
                      f.puts "#{mf.id}: #{alternate_location} will be moved to #{ideal_location}"
                      FileUtils.mkdir_p File.dirname(ideal_location)
                      FileUtils.mv alternate_location, ideal_location, :verbose => true
                      mf.file_location=ideal_location
                      mf.save!
                    end


                  end
                end
              end
            end
          end
        end
    end


  end
end
