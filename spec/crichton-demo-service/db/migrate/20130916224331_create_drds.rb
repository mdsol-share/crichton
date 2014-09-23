class CreateDrds < ActiveRecord::Migration
  def change
    create_table :drds, :id => false do |t|
      t.string   :uuid
      t.string   :name
      t.string   :status
      t.string   :kind
      t.string   :leviathan_uuid
      t.string   :leviathan_url
      t.datetime :built_at
    end
  end
end
