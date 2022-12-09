require "rails_helper"

RSpec.describe "/notifications", type: :request do
  describe "GET /index" do
    let(:patch_note_group_all_users) { create(:patch_note_group, :all_users) }
    let(:patch_note_group_no_volunteers) { create(:patch_note_group, :only_supervisors_and_admins) }
    let(:patch_note_type_a) { create(:patch_note_type, name: "patch_note_type_a") }
    let(:patch_note_type_b) { create(:patch_note_type, name: "patch_note_type_b") }
    let(:patch_note_1) { create(:patch_note, note: "*Sy@\\<iiF>(\\\"Q7", patch_note_type: patch_note_type_a) }
    let(:patch_note_2) { create(:patch_note, note: "(W!;Ros>cIWNKX}", patch_note_type: patch_note_type_b) }

    context "when logged in as an admin" do
      let(:admin) { create(:casa_admin) }

      before do
        sign_in admin
      end

      context "when there are no notifications or patch notes" do
        it "shows the no notification message" do
          get notifications_url

          expect(response.body).to include("You currently don't have any notifications. Notifications are generated when someone requests follow-up on a case contact.")
        end
      end

      context "when there are only patch notes" do
        before do
          patch_note_1.update_attribute(:patch_note_group, patch_note_group_all_users)
          patch_note_2.update_attribute(:patch_note_group, patch_note_group_no_volunteers)
        end

        context "when there is no deploy date" do
          it "shows the no notification message" do
            get notifications_url

            expect(response.body).to include("You currently don't have any notifications. Notifications are generated when someone requests follow-up on a case contact.")
          end
        end

        context "when there is a deploy date" do
          before do
            Health.instance.update_attribute(:latest_deploy_time, Date.today)
          end

          it "does not show the no notification message" do
            get notifications_url

            expect(response.body).to_not include("You currently don't have any notifications. Notifications are generated when someone requests follow-up on a case contact.")
          end
        end
      end
    end

    context "when logged in as volunteer" do
      let(:volunteer) { create(:volunteer) }

      before do
        sign_in volunteer
        Health.instance.update_attribute(:latest_deploy_time, Date.today)
        patch_note_1.update_attribute(:patch_note_group, patch_note_group_all_users)
        patch_note_2.update_attribute(:patch_note_group, patch_note_group_no_volunteers)
      end

      it "shows only the patch notes available to their user group" do
        get notifications_url

        expect(response.body).to include(CGI.escapeHTML(patch_note_1.note))
        expect(response.body).to_not include(CGI.escapeHTML(patch_note_2.note))
      end
    end
  end
end