module VideosHelper
	  # Creates a hot link to the downloadable file if it is available. File names longer
	  # than 25 characters are truncated although this can be overridden by passing in a
	  # different value
	  def file_download_label(video_asset)
		# Check to see if the file name is longer than 25 characters
		if 20 > video_asset.descMetadata.title[0].length 
		  label_display = video_asset.descMetadata.title[0]
		else
		  label_display = truncate(video_asset.descMetadata.title[0], length: 15)
                  label_display << "."
		  label_display << video_asset.descMetadata.title[0].split('.').last
		end
	  end
	  
	  # Not the best way to do this but it works for the time being
	  def free_text(content)
	    content.gsub!(/\n/, '<br />').html_safe
	  end


	  def search_result_label(item)
	     label = ''
	     unless item["title_t"].nil? or item["title_t"].empty?
	       label << item["title_t"].first
	       label << " ("
	       label << item.id
	       label << ")"
	     else
	       label << item.id
	     end
	     
	     label
	  end
	  
end


