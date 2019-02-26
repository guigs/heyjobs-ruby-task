# frozen_string_literal: true

require 'database'

class Campaign < ActiveRecord::Base
  scope :not_deleted, -> { where.not(status: 'deleted') }
end
