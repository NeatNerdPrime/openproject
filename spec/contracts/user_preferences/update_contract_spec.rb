#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'contracts/shared/model_contract_shared_context'

describe UserPreferences::UpdateContract do
  include_context 'ModelContract shared context'

  let(:current_user) { FactoryBot.build_stubbed(:user) }
  let(:user) { FactoryBot.build_stubbed :user }
  let(:user_preference) do
    FactoryBot.build_stubbed(:user_preference,
                             user: user,
                             settings: settings&.with_indifferent_access)
  end
  let(:settings) do
    {
      hide_mail: true,
      auto_hide_popups: true,
      comments_sorting: 'desc',
      daily_reminders: {
        enabled: true,
        times: %w[08:00:00+00:00 12:00:00+00:00]
      },
      time_zone: 'Brasilia',
      warn_on_leaving_unsaved: true
    }
  end
  let(:contract) { described_class.new(user_preference, current_user) }

  context 'when current_user is admin' do
    let(:current_user) { FactoryBot.build_stubbed(:admin) }

    it_behaves_like 'contract is valid'
  end

  context 'when current_user has manage_user permission' do
    before do
      allow(current_user).to receive(:allowed_to_globally?).with(:manage_user).and_return true
    end

    it_behaves_like 'contract is valid'
  end

  context 'when current_user is the own user' do
    let(:current_user) { user }

    it_behaves_like 'contract is valid'
  end

  context 'when current_user is the own user but not active' do
    let(:current_user) { user }

    before do
      allow(current_user).to receive(:active?).and_return false
    end

    it_behaves_like 'contract user is unauthorized'
  end

  context 'when current_user is anonymous' do
    let(:current_user) { User.anonymous }
    let(:user) { current_user }

    it_behaves_like 'contract user is unauthorized'
  end

  context 'when current_user is a regular user' do
    it_behaves_like 'contract user is unauthorized'
  end

  context 'when the settings are nil' do
    let(:settings) { nil }

    it_behaves_like 'contract is invalid', settings: :exclusion
  end

  context 'without a hide_mail value' do
    let(:settings) do
      {
        auto_hide_popups: true,
        comments_sorting: 'desc',
        daily_reminders: {
          enabled: true,
          times: %w[08:00:00+00:00 12:00:00+00:00]
        },
        time_zone: 'Brasilia',
        warn_on_leaving_unsaved: true
      }
    end

    it_behaves_like 'contract is invalid', hide_mail: :blank
  end

  context 'with a string for hide_mail' do
    let(:settings) do
      {
        auto_hide_popups: true,
        comments_sorting: 'desc',
        daily_reminders: {
          enabled: true,
          times: %w[08:00:00+00:00 12:00:00+00:00]
        },
        time_zone: 'Brasilia',
        warn_on_leaving_unsaved: true,
        hide_mail: 'yes please'
      }
    end

    it_behaves_like 'contract is invalid', hide_mail: :type_mismatch
  end

  context 'with a field within the daily_reminders having the wrong type' do
    let(:settings) do
      {
        auto_hide_popups: true,
        comments_sorting: 'desc',
        daily_reminders: {
          enabled: 'sure',
          times: %w[08:00:00+00:00 12:00:00+00:00]
        },
        time_zone: 'Brasilia',
        warn_on_leaving_unsaved: true,
        hide_mail: true
      }
    end

    it_behaves_like 'contract is invalid', daily_reminders: :type_mismatch_nested
  end

  context 'with a field within the daily_reminders missing' do
    let(:settings) do
      {
        auto_hide_popups: true,
        comments_sorting: 'desc',
        daily_reminders: {
          times: %w[08:00:00+00:00 12:00:00+00:00]
        },
        time_zone: 'Brasilia',
        warn_on_leaving_unsaved: true,
        hide_mail: true
      }
    end

    it_behaves_like 'contract is invalid', daily_reminders: :blank_nested
  end

  context 'with an extra property' do
    let(:settings) do
      {
        auto_hide_popups: true,
        comments_sorting: 'desc',
        daily_reminders: {
          enabled: true,
          times: %w[08:00:00+00:00 12:00:00+00:00]
        },
        time_zone: 'Brasilia',
        warn_on_leaving_unsaved: true,
        hide_mail: true,
        foo: true
      }
    end

    it_behaves_like 'contract is invalid', foo: :unknown_property
  end

  context 'with an extra property within the daily_reminders' do
    let(:settings) do
      {
        auto_hide_popups: true,
        comments_sorting: 'desc',
        daily_reminders: {
          enabled: true,
          times: %w[08:00:00+00:00 12:00:00+00:00],
          foo: true
        },
        time_zone: 'Brasilia',
        warn_on_leaving_unsaved: true,
        hide_mail: true
      }
    end

    it_behaves_like 'contract is invalid', daily_reminders: :unknown_property_nested
  end

  context 'with an invalid time for the daily_reminders' do
    let(:settings) do
      {
        auto_hide_popups: true,
        comments_sorting: 'desc',
        daily_reminders: {
          enabled: true,
          times: %w[abc 12:00:00+00:00]
        },
        time_zone: 'Brasilia',
        warn_on_leaving_unsaved: true,
        hide_mail: true
      }
    end

    it_behaves_like 'contract is invalid', daily_reminders: :format_nested
  end

  context 'with an invalid order for comments_sorting' do
    let(:settings) do
      {
        auto_hide_popups: true,
        comments_sorting: 'up',
        daily_reminders: {
          enabled: true,
          times: %w[08:00:00+00:00 12:00:00+00:00]
        },
        time_zone: 'Brasilia',
        warn_on_leaving_unsaved: true,
        hide_mail: true
      }
    end

    it_behaves_like 'contract is invalid', comments_sorting: :inclusion
  end
end
