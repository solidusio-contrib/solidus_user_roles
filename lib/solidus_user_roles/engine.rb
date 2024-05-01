# frozen_string_literal: true

require 'solidus_core'
require 'solidus_support'

module SolidusUserRoles
  class Engine < Rails::Engine
    include SolidusSupport::EngineExtensions

    isolate_namespace ::Spree

    engine_name 'solidus_user_roles'
    config.autoload_paths += %W(#{config.root}/lib)

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    def self.load_custom_permissions
      # We do not need to load custom permissions when running the `asset:precompile` Rake task.
      return if asset_precompilation_step?

      # Ensure connection to DB is available and both tables exist before assigning permissions
      if database_connection_available? &&
          (ActiveRecord::Base.connection.tables & ['spree_roles', 'spree_permission_sets']).to_a.length == 2
        ::Spree::Role.non_base_roles.each do |role|
          ::Spree::Config.roles.assign_permissions role.name, role.permission_sets_constantized
        end
      end
    rescue ActiveRecord::NoDatabaseError
      warn "No database available, skipping role configuration"
    rescue ActiveRecord::StatementInvalid => e
      warn "Skipping role configuration: #{e.message}"
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')).sort.each do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
      return if Rails.env.test?

      SolidusUserRoles::Engine.load_custom_permissions
    end

    config.to_prepare(&method(:activate).to_proc)

    private

    def self.asset_precompilation_step?
      ARGV.include? "assets:precompile"
    end

    def self.database_connection_available?
      ActiveRecord::Base.connection rescue false

      ActiveRecord::Base.connected?
    end
  end
end
