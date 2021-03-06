require "minitest_helper"

class TestMarketoAPICampaigns < Minitest::Test
  include MarketoTestHelper

  def setup
    super
    @subject = @client.campaigns
  end

  def test_for_marketo
    assert subject.respond_to? :for_marketo
    stub_specialized :for_source do
      assert_equal :MKTOWS, subject.for_marketo.first
    end
    stub_soap_call do
      method, options = subject.for_marketo
      assert_equal :get_campaigns_for_source, method
      assert_equal({ source: :MKTOWS }, options)
    end
  end

  def test_for_sales
    assert subject.respond_to? :for_sales
    stub_specialized :for_source do
      assert_equal :SALES, subject.for_sales.first
    end
    stub_soap_call do
      method, options = subject.for_sales
      assert_equal :get_campaigns_for_source, method
      assert_equal({ source: :SALES }, options)
    end
  end

  def test_for_source_bad_source
    assert_raises(ArgumentError) { subject.for_source :bad_source }
  end

  def test_for_source_marketo_name
    stub_soap_call do
      method, options = subject.for_source :marketo, 'John'
      assert_equal :get_campaigns_for_source, method
      assert_equal({ source: :MKTOWS, name: 'John' }, options)
    end
  end

  def test_for_source_sales_name_exact
    stub_soap_call do
      method, options = subject.for_source :marketo, 'John', true
      assert_equal :get_campaigns_for_source, method
      assert_equal({ source: :MKTOWS, name: 'John', exactName: true },
                   options)
    end
  end

  def test_request_marketo
    assert subject.respond_to? :request_marketo
    stub_specialized :request do
      options = subject.request_marketo.first
      assert_equal({ source: :MKTOWS }, options)
    end
  end

  def test_request_sales
    assert subject.respond_to? :request_sales
    stub_specialized :request do
      options = subject.request_sales.first
      assert_equal({ source: :SALES }, options)
    end
  end

  def test_request_missing_leads
    assert_raises_with_message(ArgumentError, ':lead or :leads must be provided') {
      subject.request
    }
  end

  def test_request_missing_campaign_or_program
    assert_raises(ArgumentError,
                  ':campaignId, :campaignName, or :programName must be provided') {
      subject.request(lead: :foo)
    }
  end

  def test_request_program_tokens_with_no_program_name
    assert_raises_with_message(KeyError,
                               ':program_name must be provided when using :program_tokens') {
      subject.request(lead: :foo, campaign_id: 5, program_tokens: [ 3 ])
    }
  end

  def test_request_with_campaign_id_and_name
    assert_raises_with_message(ArgumentError,
                               ':campaign_id and :campaign_name are mutually exclusive') {
      subject.request(lead: :foo, campaign_id: 5, campaign_name: 'Five')
    }
  end

  def test_request_bad_source
    assert_raises_with_message(ArgumentError, 'Invalid source bad_source') {
      subject.request(lead: :foo, campaign_id: 5, source: :bad_source)
    }
  end

  def test_request_merged_leads_campaign_id_default_source
    stub_soap_call do
      method, options = subject.request(lead:        lead_key(3),
                                        leads:       lead_keys(4, 5),
                                        campaign_id: 3)
      assert_equal :request_campaign, method
      refute_missing_keys options, :source, :leadList, :campaignId
      assert_equal :MKTOWS, options[:source]
      assert_equal lead_keys(4, 5, 3), options[:leadList]
      assert_equal 3, options[:campaignId]
      assert_missing_keys options, :campaignName, :programName,
        :programTokens
    end
  end

  def test_request_using_campaign_name
    stub_soap_call do
      method, options = subject.request(lead:          lead_key(3),
                                        campaign_name: 'earthday')
      assert_equal :request_campaign, method
      assert_equal :MKTOWS, options[:source]
      assert_equal [ lead_key(3) ], options[:leadList]
      assert_equal 'earthday', options[:campaignName]
      assert_missing_keys options, :campaignId, :programName,
        :programTokens
    end
  end

  def test_request_using_program_name
    stub_soap_call do
      method, options = subject.request(lead:         lead_key(3),
                                        program_name: 'earthday')
      assert_equal :request_campaign, method
      refute_missing_keys options, :source, :leadList, :programName
      assert_equal :MKTOWS, options[:source]
      assert_equal [ lead_key(3) ], options[:leadList]
      assert_equal 'earthday', options[:programName]
      assert_missing_keys options, :campaignName, :campaignId,
        :programTokens
    end
  end

  def test_schedule
    stub_soap_call do
      method, options = subject.schedule('program', 'campaign')
      assert_equal :schedule_campaign, method
      assert_equal({ programName: 'program', campaignName: 'campaign' }, options)
    end
  end

  def test_schedule_with_run_at
    stub_soap_call do
      method, options = subject.schedule('program', 'campaign', run_at: 3)
      assert_equal :schedule_campaign, method
      assert_equal({
        programName:   'program',
        campaignName:  'campaign',
        campaignRunAt: 3
      }, options)
    end
  end

  def test_schedule_with_program_tokens
    stub_soap_call do
      method, options = subject.schedule('program', 'campaign', program_tokens: [ :x ])
      assert_equal :schedule_campaign, method
      assert_equal({
        programName:      'program',
        campaignName:     'campaign',
        programTokenList: [ :x ]
      }, options)
    end
  end
end
