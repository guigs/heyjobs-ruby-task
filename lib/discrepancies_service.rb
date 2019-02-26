# frozen_string_literal: true

require 'json'
require 'net/http'
require 'campaign'

class DiscrepanciesService
  def self.call
    new.call
  end

  def call
    detect_discrepancies
  end

  private

  def remote_campaigns
    uri = URI('https://mockbin.org/bin/fcb30500-7b98-476f-810d-463a0b8fc3df')
    result = Net::HTTP.get(uri)
    JSON.parse(result).fetch('ads')
  end

  def local_campaigns
    @local_campaigns ||= Campaign.all.index_by(&:external_reference)
  end

  def detect_discrepancies
    remote_campaigns.map do |remote_campaign|
      remote_reference = remote_campaign.fetch('reference')
      {
        remote_reference: remote_reference,
        discrepancies: discrepancies_between(remote_campaign, local_campaign(remote_reference))
      }
    end
  end

  def local_campaign(external_reference)
    local_campaigns[external_reference]
  end

  def discrepancies_between(remote_campaign, local_campaign)
    [
      discrepancy_for(
        :status,
        remote: remote_campaign.fetch('status'),
        local: local_campaign&.status
      ),
      discrepancy_for(
        :description,
        remote: remote_campaign.fetch('description'),
        local: local_campaign&.ad_description
      )
    ].compact.to_h
  end

  def discrepancy_for(attribute, remote:, local:)
    return if remote == local
    [attribute, { remote: remote, local: local }]
  end
end
