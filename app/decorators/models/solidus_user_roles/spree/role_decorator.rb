# frozen_string_literal: true

module SolidusUserRoles
  module Spree
    module RoleDecorator
      def self.prepended(base)
        base.has_many :role_permissions, dependent: :destroy
        base.has_many :permission_sets, through: :role_permissions

        base.scope :non_base_roles, -> { where.not(name: ['admin', 'user']) }
        base.validates_uniqueness_of :name, case_sensitive: false
        base.after_save :assign_permissions
      end

      def permission_sets_constantized
        permission_sets.map(&:set).map(&:constantize)
      end

      def assign_permissions
        ::Spree::Config.roles.assign_permissions name, permission_sets_constantized
      end

      ::Spree::Role.prepend self
    end
  end
end
