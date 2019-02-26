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
            discrepancies: [
              { property: 'status', remote: 'enabled', local: nil },
              { property: 'description', remote: 'Description for campaign 11', local: nil }
            ]
          },
          {
            remote_reference: '2',
            discrepancies: [
              { property: 'status', remote: 'disabled', local: nil },
              { property: 'description', remote: 'Description for campaign 12', local: nil }
            ]
          },
          {
            remote_reference: '3',
            discrepancies: [
              { property: 'status', remote: 'enabled', local: nil },
              { property: 'description', remote: 'Description for campaign 13', local: nil }
            ]
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
          discrepancies: [
            {
              property: 'description',
              remote: 'Description for campaign 11',
              local: 'Local description'
            }
          ]
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
          discrepancies: [
            {
              property: 'status',
              remote: 'enabled',
              local: 'paused'
            },
            {
              property: 'description',
              remote: 'Description for campaign 11',
              local: 'Local description'
            }
          ]
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
            discrepancies: []
          },
          {
            remote_reference: '2',
            discrepancies: []
          },
          {
            remote_reference: '3',
            discrepancies: []
          }
        ]
      )
    end
  end

  context 'local campaigns missing remote' do
    before do
      Campaign.create!(
        job_id: 4,
        status: 'active',
        external_reference: '4',
        ad_description: 'Description for campaign 14'
      )
      Campaign.create!(
        job_id: 5,
        status: 'deleted',
        external_reference: '5',
        ad_description: 'Description for campaign 15'
      )
    end

    it 'reports discrepancies for non deleted local campaigns' do
      results = DiscrepanciesService.call
      expect(results.size).to eq(4)
      expect(results).to include(
        {
          remote_reference: '4',
          discrepancies: [
            { property: 'status', remote: nil, local: 'active' },
            { property: 'description', remote: nil, local: 'Description for campaign 14' }
          ]
        }
      )
    end
  end
end
