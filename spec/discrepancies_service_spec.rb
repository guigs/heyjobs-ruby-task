# frozen_string_literal: true

require 'support/vcr'
require 'discrepancies_service'

RSpec.describe DiscrepanciesService, '#call' do
  around do |example|
    VCR.use_cassette('remote_campaigns_api_sample') do
      example.run
    end
  end

  context 'missing local campaigns' do
    it 'reports discrepancies with all local attributes considered nil' do
      expect(DiscrepanciesService.call).to eq(
        [
          {
            remote_reference: '1',
            discrepancies: {
              status: { remote: 'enabled', local: nil },
              description: { remote: 'Description for campaign 11', local: nil }
            }
          },
          {
            remote_reference: '2',
            discrepancies: {
              status: { remote: 'disabled', local: nil },
              description: { remote: 'Description for campaign 12', local: nil }
            }
          },
          {
            remote_reference: '3',
            discrepancies: {
              status: { remote: 'enabled', local: nil },
              description: { remote: 'Description for campaign 13', local: nil }
            }
          }
        ]
      )
    end
  end

  context 'local campaign with discrepancies on single attribute' do
    before do
      Campaign.create!(
        job_id: 1,
        status: 'active',
        external_reference: '1',
        ad_description: 'Local description'
      )
    end

    it 'reports discrepancy in description attribute' do
      expect(DiscrepanciesService.call).to include(
        {
          remote_reference: '1',
          discrepancies: {
            description: {
              remote: 'Description for campaign 11',
              local: 'Local description'
            }
          }
        }
      )
    end
  end

  context 'local campaign with discrepancies on multiple attributes' do
    before do
      Campaign.create!(
        job_id: 1,
        status: 'paused',
        external_reference: '1',
        ad_description: 'Local description'
      )
    end

    it 'reports discrepancies in both attributes' do
      expect(DiscrepanciesService.call).to include(
        {
          remote_reference: '1',
          discrepancies: {
            status: {
              remote: 'enabled',
              local: 'paused'
            },
            description: {
              remote: 'Description for campaign 11',
              local: 'Local description'
            }
          }
        }
      )
    end
  end

  context 'no discrepancies' do
    before do
      Campaign.create!(
        job_id: 1,
        status: 'active',
        external_reference: '1',
        ad_description: 'Description for campaign 11'
      )
      Campaign.create!(
        job_id: 2,
        status: 'paused',
        external_reference: '2',
        ad_description: 'Description for campaign 12'
      )
      Campaign.create!(
        job_id: 3,
        status: 'active',
        external_reference: '3',
        ad_description: 'Description for campaign 13'
      )
    end

    it 'reports no discrepancies' do
      expect(DiscrepanciesService.call).to match_array(
        [
          {
            remote_reference: '1',
            discrepancies: {}
          },
          {
            remote_reference: '2',
            discrepancies: {}
          },
          {
            remote_reference: '3',
            discrepancies: {}
          }
        ]
      )
    end
  end
end
