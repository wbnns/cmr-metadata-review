require 'test_helper'
Dir[Rails.root.join('test/**/*.rb')].each {|f| require f}

class AssociatingGranulesTest < Capybara::Rails::TestCase
  include Helpers::UserHelpers

  before do
    OmniAuth.config.test_mode = true
    mock_login(role: 'arc_curator')

    stub_request(:get, "#{Cmr.get_cmr_base_url}/search/granules.echo10?concept_id=G309210-GHRC")
      .with(
        headers: {'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Accept' => '*/*', 'User-Agent' => 'Ruby'}
      )
      .to_return(status: 200, body: '<?xml version="1.0" encoding="UTF-8"?><results><hits>0</hits><took>32</took></results>', headers: {})
  end

  describe 'Granule Assocations' do
    describe 'associate granules to collections' do
      it 'can assign granule to collection' do
        visit '/home'
        wait_for_jQuery(5)

        all('#record_id_')[0].click # Selects the first collection record in the list
        find('#open > div > div.navigate-buttons > input').click # click the See Review Details button
        first("#associated_granule_value").find("option[value='Undefined']").click # other tests are not cleaning up db, so reset it back manually
        first("#associated_granule_value").find("option[value='5']").click # Click in select box for what granule to associate
        page.must_have_content('Granule G309210-GHRC/1 has been successfully associated to this collection revision 9.')
      end

      it 'can assign "no granule review" to a collection' do
        visit '/home'
        wait_for_jQuery(5)

        all('#record_id_')[0].click # Selects the first collection record in the list
        find('#open > div > div.navigate-buttons > input').click # click the See Review Details button
        first("#associated_granule_value").find("option[value='Undefined']").click # other tests are not cleaning up db, so reset it back manually
        first("#associated_granule_value").find("option[value='No Granule Review']").click # Clicks No Granule Review Option
        page.must_have_content("associated granule will be marked as 'No Granule Review'")
      end

    end

    describe 'associated granule reports' do
      it 'associated granule shows up in reports' do
        mock_login(role: 'admin')
        visit '/home'
        wait_for_jQuery(5)

        all('#record_id_')[1].click # Selects the checkbox in "in daac review"
        find('#in_daac_review > div > div.navigate-buttons > input.selectButton').click # Clicks the See Review Details button
        first("#associated_granule_value").find("option[value='Undefined']").click # other tests are not cleaning up db, so reset it back manually
        first("#associated_granule_value").find("option[value='5']").click # Click in select box for what granule to associate
        page.must_have_content('Granule G309210-GHRC/1 has been successfully associated to this collection revision 9.')
        visit '/home' # go back to home page
        all('#record_id_')[1].click # select the record again in "in daac review"
        find('#in_daac_review > div > div.navigate-buttons > input.reportButton').click # click the report button
        page.must_have_content('C1000000020-LANCEAMSR2-9') # verify the collection record is in the report
        page.must_have_content('G309210-GHRC-1') # verify the granule association is in the report
        page.must_have_content('RECORD METRICS') # verify it has report metrics
        page.assert_selector('.checked_num', count: 2) # of elements reviewed appears twice.
      end
    end
  end

  # Note had to move this test of the main tests as we were not getting proper database cleanup after each test
  describe 'mark as undefined' do
    it 'can mark a granule back to undefined' do
      visit '/home'
      wait_for_jQuery(5)

      all('#record_id_')[0].click # select the first collection in the list
      find('#open > div > div.navigate-buttons > input').click # click the See Review Details button
      first("#associated_granule_value").find("option[value='Undefined']").click # other tests are not cleaning up db, so reset it back manually
      first("#associated_granule_value").find("option[value='5']").click # select the granule to associate with the collection
      page.must_have_content('Granule G309210-GHRC/1 has been successfully associated to this collection revision 9.')
      first("#associated_granule_value").find("option[value='Undefined']").click # select undefined to set it back
      page.must_have_content("associated granule will be marked as 'Undefined'")
    end
  end
end

