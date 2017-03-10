# Copyright 2011-2017, The Trustees of Indiana University and Northwestern
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

module DerivativeBehavior
  def absolute_location
    derivativeFile
  end

  def tokenized_url(token, mobile = false)
    uri = streaming_url(mobile)
    "#{uri}?token=#{token}".html_safe
  end

  def streaming_url(is_mobile = false)
    is_mobile ? hls_url : location_url
  end

  def format
    if video_codec.present?
      'video'
    elsif audio_codec.present?
      'audio'
    else
      'other'
    end
  end
end
