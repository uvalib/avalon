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
              elsif (!mf.file_checksum.to_s.empty?) then
                md5sum = Digest::MD5.file recorded_location
                if (md5sum.to_s != mf.file_checksum.to_s) then
                  output = "In collection #{c.pid} for media object #{mo.id.to_s}, the master file #{mf.id.to_s} at \"#{mf.file_location.to_s}\" has the checksum #{md5sum.to_s} instead of #{mf.file_checksum.to_s}!"
                end
              end
            end
          end
        end
      end
    end
  end
end
