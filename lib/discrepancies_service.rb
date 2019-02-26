# frozen_string_literal: true

require 'json'
require 'net/http'
require 'campaign'

class DiscrepanciesService
  def self.call
    new.call
  end

  def call
    discrepancies_with_remote + discrepancies_missing_remote
  end

  private

  def remote_campaigns
    @remote_campaigns ||= fetch_remote_campaigns
  end

  def fetch_remote_campaigns
    uri = URI('https://mockbin.org/bin/fcb30500-7b98-476f-810d-463a0b8fc3df')
    result = Net::HTTP.get(uri)
    JSON.parse(result).fetch('ads')
  end

  def external_references
    remote_campaigns.map { |remote_campaign| remote_campaign.fetch('reference') }
  end

  def local_campaigns_by_external_reference
    @local_campaigns_by_external_reference ||= Campaign.where(external_reference: external_references).index_by(&:external_reference)
  end

  def local_campaigns_missing_remote
    Campaign.not_deleted.where.not(external_reference: external_references)
  end

  def discrepancies_with_remote
    remote_campaigns.map do |remote_campaign|
      remote_reference = remote_campaign.fetch('reference')
      {
        remote_reference: remote_reference,
        discrepancies: discrepancies_between(remote_campaign, local_campaign(remote_reference))
      }
    end
  end

  def discrepancies_missing_remote
    local_campaigns_missing_remote.map do |local_campaign_missing_remote|
      {
        remote_reference: local_campaign_missing_remote.external_reference,
        discrepancies: discrepancies_between(nil, local_campaign_missing_remote)
      }
    end
  end

  def local_campaign(external_reference)
    local_campaigns_by_external_reference[external_reference]
  end

  def discrepancies_between(remote_campaign, local_campaign)
    [
      status_discrepancy(
        remote: remote_campaign&.fetch('status'),
        local: local_campaign&.status
      ),
      description_discrepancy(
        remote: remote_campaign&.fetch('description'),
        local: local_campaign&.ad_description
      )
    ].compact.to_h
  end

  def description_discrepancy(remote:, local:)
    return if remote == local
    [:description, { remote: remote, local: local }]
  end

  def status_discrepancy(remote:, local:)
    return if status_equivalence(remote: remote, local: local)
    [:status, { remote: remote, local: local }]
  end

  def status_equivalence(remote:, local:)
    remote == 'enabled' && local == 'active' ||
    remote == 'disabled' && local == 'paused'
  end
end
