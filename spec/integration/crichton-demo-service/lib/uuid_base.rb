class UuidBase < ActiveRecord::Base
  self.primary_key = :uuid
  self.table_name = :drds
  attr_accessible :uuid, :status, :leviathan_uuid, :kind, :built_at, :name, :leviathan_url

  before_create :generate_defaults

  def to_key
    [uuid]
  end

  def generate_defaults
    self.uuid = SecureRandom.uuid
    self.status ||= 'activated'
    self.kind ||= 'standard'
    self.leviathan_url = "http://farscape.example.org/leviathan/#{self.leviathan_uuid || SecureRandom.uuid}"
    self.built_at = Time.now
  end
end
