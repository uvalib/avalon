# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
# 
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed 
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the 
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

module MediaObjectsHelper
      # Quick and dirty solution to the problem of displaying the right template.
      # Quick and dirty also gets it done faster.
      def current_step_for(status=nil)
        if status.nil?
          status = HYDRANT_STEPS.first
        end
        
        HYDRANT_STEPS.template(status)
      end
     
      # Based on the current context it will choose which class should be
      # applied to the display. If you are not using Twitter Bootstrap or
      # want different defaults then change them here.
      #
      # The context here is the media_object you are working with.
      def class_for_step(context, step)  
        css_class = case 
          # when context.workflow.current?(step)
          #   'nav-info'
          when context.workflow.completed?(step)
            'nav-success'
          else 'nav-disabled' 
          end

        css_class
     end

     def form_id_for_step(step)
       "#{step.gsub('-','_')}_form"
     end

     def dropbox_url collection
        ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
        path = URI::Parser.new.escape(collection.dropbox_directory_name, %r{[/\\%& #]})
        url = File.join(Avalon::Configuration.lookup('dropbox.upload_uri'), path)
        ic.iconv(url)
     end
     
     def combined_display_date mediaobject
       (issued,created) = case mediaobject
       when MediaObject
         [mediaobject.date_issued, mediaobject.date_created]
       when Hash
         [mediaobject[:document]['date_ssi'], mediaobject[:document]['date_created_ssi']]
       end
       result = issued
       result += " (Creation date: #{created})" if created.present?
       result
     end

     def display_language mediaobject
       mediaobject.language.collect{|l|l[:text]}
     end

     def display_related_item mediaobject
       mediaobject.related_item_url.collect{ |r| link_to( r[:label], r[:url]) }
     end

     def current_quality stream_info
       available_qualities = Array(stream_info[:stream_flash]).collect {|s| s[:quality]}
       available_qualities += Array(stream_info[:stream_hls]).collect {|s| s[:quality]}
       available_qualities.uniq!
       quality ||= session[:quality] if session['quality'].present? && available_qualities.include?(session[:quality])
       quality ||= Avalon::Configuration.lookup('streaming.default_quality') if available_qualities.include?(Avalon::Configuration.lookup('streaming.default_quality'))
       quality ||= available_qualities.first
       quality
     end

     def parse_hour_min_sec s
       return nil if s.nil?
       smh = s.split(':').reverse
       (Float(smh[0]) rescue 0) + 60*(Float(smh[1]) rescue 0) + 3600*(Float(smh[2]) rescue 0)
     end

     def parse_media_fragment fragment
       return 0,nil if !fragment.present?
       f_start,f_end = fragment.split(',')
       return parse_hour_min_sec(f_start) , parse_hour_min_sec(f_end)
     end

     def is_current_section? section
        section.pid == @currentStream.pid
     end

     def hide_sections? sections
       sections.blank? or (sections.length == 1 && sections.first.structuralMetadata.toXML.nil?)
     end

     def structure_html section, index, show_progress
       current = is_current_section? section

       headeropen = <<EOF
    <div class="panel-heading" role="tab" id="heading#{index}">
      <a data-toggle="collapse" href="#section#{index}" aria-expanded="#{current ? 'true' : 'false' }" aria-controls="collapse#{index}">
        <h4 class="panel-title">
EOF
       headerclose = <<EOF
        </h4>
      </a>
    </div>
EOF
       progress_div = show_progress ? '<div class="status-detail alert progress-indented" style="display: none"></div>' : ''

       sm = section.structuralMetadata.toXML

       # If there is no structural metadata associated with this masterfile return the stream info
       if sm.nil?
         mydata = {segment: section.pid, is_video: section.is_video?, share_link: share_link_for(section)} 
         myclass = current ? 'current-stream' : nil
         sectionlabel = "#{index+1}. #{stream_label_for(section)}"
         sectionlabel += " (#{milliseconds_to_formatted_time(section.duration.to_i)})" unless section.duration.blank?
         link = link_to sectionlabel, share_link_for( section ), data: mydata, class: myclass 
         return "#{headeropen}<ul><li class='stream-li #{ 'progress-indented' if progress_div.present? }'>#{link}#{progress_div}</li></ul>#{headerclose}"
       end

       sectionnode = sm.xpath('//Item')
       sectionlabel = "#{index+1}. #{sectionnode.attribute('label').value}"
       sectionlabel += " (#{milliseconds_to_formatted_time(section.duration.to_i)})" unless section.duration.blank?

       # If there are subsections within structure, build a collapsible panel with the contents
       if sectionnode.children.present?
         tracknumber = 0
         contents = ''
         sectionnode.children.each do |node| 
           st, tracknumber = parse_node section, node, tracknumber, progress_div
           contents+=st
         end
         s = <<EOF
   #{headeropen}
          <span class="fa fa-minus-square #{current ? '' : 'hidden'}"></span>
          <span class="fa fa-plus-square #{current ? 'hidden' : ''}"></span>
          <ul><li><span>#{sectionlabel}</span></li></ul>
   #{headerclose}
    <div id="section#{index}" class="panel-collapse collapse #{current ? 'in' : ''}" role="tabpanel" aria-labelledby="heading#{index}">
      <div class="panel-body">
        <ul>#{contents}</ul>
      </div>
    </div>
EOF
       # If there are so subsections within the structure, return just the header with the single section
       else
         st, tracknumber = parse_node section, sectionnode.first, index, progress_div
         s = "#{headeropen}<span><ul>#{st}</ul></span>#{headerclose}"
       end
     end

     def parse_node section, node, tracknumber, progress_div
       if node.name.upcase=="DIV"
         contents = ''
         node.children.each { |n| nodecontent, tracknumber = parse_node section, n, tracknumber, progress_div; contents+=nodecontent }
         return "<li>#{node.attribute('label')}</li><li><ul>#{contents}</ul></li>", tracknumber
       elsif ['SPAN','ITEM'].include? node.name.upcase
         tracknumber += 1
         start = node.attribute('begin').present? ? node.attribute('begin').value : 0
         stop = node.attribute('end').present? ? node.attribute('end').value : section.duration.blank? ? 0 : milliseconds_to_formatted_time(section.duration.to_i)
         start,stop = parse_media_fragment "#{start},#{stop}"
         node_duration = milliseconds_to_formatted_time((stop.to_i-start.to_i)*1000)
         label = "#{tracknumber}. #{node.attribute('label').value} (#{node_duration})"
         url = "#{share_link_for( section )}?t=#{start},#{stop}"
         data =  {segment: section.pid, is_video: section.is_video?, share_link: url, fragmentbegin: start, fragmentend: stop}
         myclass = section.pid == @currentStream.pid ? 'current-stream' : nil
         link = link_to label, url, data: data, class: myclass
         return "<li class='stream-li #{ 'progress-indented' if progress_div.present? }'>#{link}#{progress_div}</li>", tracknumber
       end
     end

end
