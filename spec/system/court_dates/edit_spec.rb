require "rails_helper"

RSpec.describe "court_dates/edit", type: :system do
  context "with date"
  let(:now) { Date.new(2021, 1, 1) }
  let(:organization) { create(:casa_org) }
  let(:admin) { create(:casa_admin, casa_org: organization) }
  let(:volunteer) { create(:volunteer) }
  let(:supervisor) { create(:casa_admin, casa_org: organization) }
  let!(:casa_case) { create(:casa_case, casa_org: organization) }
  let!(:court_date) { create(:court_date, :with_court_details, casa_case: casa_case, date: now - 1.week) }

  before do
    travel_to now
    sign_in admin
    visit root_path
    click_on "Cases"
    click_on casa_case.case_number
    click_on "Edit Case Details"
    click_on court_date.date.strftime("%B %-d, %Y")
    click_on "Edit"
  end

  it "shows court orders" do
    court_order = court_date.case_court_orders.first

    expect(page).to have_text(court_order.text)
    expect(page).to have_text(court_order.implementation_status.humanize)
  end

  it "edits past court date", js: true do
    expect(page).to have_text("Editing Court Date")
    expect(page).to have_text("Add Court Date")
    expect(page).to have_field("court_date_date", with: "2020-12-25")
    expect(page).to have_text("Case Number:")
    expect(page).to have_text(casa_case.case_number)
    expect(page).to have_select("Judge")
    expect(page).to have_select("Hearing type")
    expect(page).to have_text("Court Orders - Please check that you didn't enter any youth names")
    expect(page).to have_text("Add a court order")

    page.find("#add-mandate-button").click
    find("#court-orders-list-container").first("textarea").send_keys("Court Order Text One")

    within ".top-page-actions" do
      click_on "Update"
    end
    expect(page).to have_text("Court Order Text One")
  end

  it "can delete a court date as admin", js: true do
    visit root_path
    click_on "Cases"
    click_on casa_case.case_number
 
    expect(CourtDate.count).to eq 1
    expect(page).to have_content court_date.date.strftime("%B %-d, %Y")
    page.find('a', text: court_date.date.strftime("%B %-d, %Y")).click
    page.find('a', text: "Delete Future Court Date").click
    page.driver.browser.switch_to.alert.accept

    expect(page).to have_content "Court date was successfully deleted."
    expect(CourtDate.count).to eq 0
  end

  it "can delete a court date as supervisor", js: true do
    sign_out admin
    sign_in supervisor

    visit root_path
    click_on "Cases"
    click_on casa_case.case_number

    expect(CourtDate.count).to eq 1
    expect(page).to have_content court_date.date.strftime("%B %-d, %Y")
    page.find('a', text: court_date.date.strftime("%B %-d, %Y")).click
    page.find('a', text: "Delete Future Court Date").click
    page.driver.browser.switch_to.alert.accept

    expect(page).to have_content "Court date was successfully deleted."
    expect(CourtDate.count).to eq 0
  end

  it "can't delete a court date as volunteer", js: true do
    sign_out admin
    volunteer.casa_cases = [casa_case]
    sign_in volunteer

    visit root_path
    click_on "Cases"
    click_on casa_case.case_number

    expect(CourtDate.count).to eq 1
    expect(page).to have_content court_date.date.strftime("%B %-d, %Y")
    page.find('a', text: court_date.date.strftime("%B %-d, %Y")).click
    expect(page).not_to have_content "Delete Future Court Date"
  end
end