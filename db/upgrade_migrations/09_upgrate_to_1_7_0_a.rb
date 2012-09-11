class UpgradeTo170A < ActiveRecord::Migration
  def self.up
    add_column :cms_pages, :force_ssl, :boolean, :default => false
  end

  def self.down
    remove_column :cms_pages, :force_ssl
  end
end
