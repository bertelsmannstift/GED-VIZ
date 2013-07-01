require_dependency 'keyframe'

class Presentation < ActiveRecord::Base

  attr_accessor :keyframes

  before_save :serialize_keyframes
  after_save :clean_cache
  after_find :deserialize_keyframes

  def initialize(attributes = {}, options = {})
    super
    self.keyframes ||= []
  end

  def self.cached_json(id)
    json = Rails.cache.read("presentation_#{id}")
    if !json
      presentation = Presentation.find(id)
      json = presentation.to_json
      Rails.cache.write "presentation_#{id}", json
    end
    return json
  end

  def self.from_json(json_hash, id=nil)
    json_hash = json_hash.symbolize_keys
    json_hash.delete :id
    presentation = if id
                     Presentation.find(id)
                   else
                     Presentation.new()
                   end
    presentation.from_json(json_hash)
  end

  def serialize_keyframes
    keyframe_json = keyframes.map do |keyframe|
      keyframe.as_json.tap do |j|
        j.delete :elements
        j.delete :yearly_totals
      end
    end
    write_attribute(:keyframes, keyframe_json.to_json)
  end

  def deserialize_keyframes
    keyframes_string = read_attribute(:keyframes)
    return if keyframes_string.nil?
    raw_keyframes = JSON.parse(keyframes_string, create_additions: false)
    @keyframes = raw_keyframes.map do |keyframe|
      Keyframe.from_json(keyframe)
    end
  end

  def clean_cache
    Rails.cache.delete "presentation_#{id}"
    PresentationRenderer.new(self).clear!
  end

  def add_keyframe(k)
    self.keyframes << k
  end

  def serializable_hash(options={})
    options = {} if options.nil?
    options[:methods] = [] unless options.has_key?(:methods)
    options[:methods] << :keyframes
    super(options)
  end

  # Update the presentation from a plain object input
  def from_json(json_hash)
    json_hash = json_hash.symbolize_keys
    self.title = json_hash[:title]
    self.keyframes = json_hash[:keyframes].map do |keyframe_hash|
      Keyframe.from_json(keyframe_hash)
    end
    self
  end

end