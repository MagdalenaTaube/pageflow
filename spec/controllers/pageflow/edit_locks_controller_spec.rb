require 'spec_helper'

module Pageflow
  describe EditLocksController do
    routes { Engine.routes }
    render_views

    describe '#create' do
      context 'when not locked' do
        it 'succeeds for member of the entry' do
          user = create(:user)
          entry = create(:entry, :with_member => user)

          sign_in(user)
          post(:create, :entry_id => entry, :format => :json)

          expect(response.status).to eq(201)
        end

        it 'responds with id of created edit lock' do
          user = create(:user)
          entry = create(:entry, :with_member => user)

          sign_in(user)
          post(:create, :entry_id => entry, :format => :json)

          expect(json_response(:path => ['id'])).to eq(entry.edit_lock.id)
        end

        it 'locks the entry for the current user' do
          user = create(:user)
          entry = create(:entry, :with_member => user)

          sign_in(user)
          post(:create, :entry_id => entry, :format => :json)

          expect(entry.edit_lock).to be_held_by(user)
        end

        it 'requires the signed in user to be member of the parent entry' do
          user = create(:user)
          entry = create(:entry)

          sign_in(user)
          post(:create, :entry_id => entry, :format => :json)

          expect(response.status).to eq(403)
        end

        it 'requires authentication' do
          entry = create(:entry)

          post(:create, :entry_id => entry, :format => :json)

          expect(response.status).to eq(401)
        end
      end

      context 'when lockeded by other user' do
        it 'responds with conflict' do
          user = create(:user)
          entry = create(:entry, :with_member => user)
          entry.edit_lock.aquire(create(:user))

          sign_in(user)
          post(:create, :entry_id => entry, :format => :json)

          expect(response.status).to eq(409)
        end

        it 'does not break other users lock' do
          user = create(:user)
          other_user = create(:user)
          entry = create(:entry, :with_member => user)
          entry.edit_lock.aquire(other_user)

          sign_in(user)
          post(:create, :entry_id => entry, :format => :json)

          expect(entry.edit_lock).to be_held_by(other_user)
        end

        context 'with force attribute' do
          it 'responds with success' do
            user = create(:user)
            entry = create(:entry, :with_member => user)
            entry.edit_lock.aquire(create(:user))

            sign_in(user)
            post(:create, :entry_id => entry, :edit_lock => {:force => true}, :format => :json)

            expect(response.status).to eq(201)
          end

          it 'responds with id of created edit lock' do
            user = create(:user)
            entry = create(:entry, :with_member => user)
            entry.edit_lock.aquire(create(:user))

            sign_in(user)
            post(:create, :entry_id => entry, :edit_lock => {:force => true}, :format => :json)

            expect(json_response(:path => ['id'])).to eq(entry.reload.edit_lock.id)
          end

          it 'does not break other users lock' do
            user = create(:user)
            other_user = create(:user)
            entry = create(:entry, :with_member => user)
            entry.edit_lock.aquire(other_user)

            sign_in(user)
            post(:create, :entry_id => entry, :edit_lock => {:force => true}, :format => :json)

            expect(entry.reload.edit_lock).to be_held_by(user)
          end
        end
      end
    end

    describe '#update' do
      context 'when not locked' do
        it 'succeeds for member of the entry' do
          user = create(:user)
          entry = create(:entry, :with_member => user)

          sign_in(user)
          put(:update, :entry_id => entry, :edit_lock => {:id => 'not_there_anymore'})

          expect(response.status).to eq(204)
        end

        it 'locks the entry for the current user' do
          user = create(:user)
          entry = create(:entry, :with_member => user)

          sign_in(user)
          put(:update, :entry_id => entry, :edit_lock => {:id => 'not_there_anymore'})

          expect(entry.edit_lock).to be_held_by(user)
        end

        it 'requires the signed in user to be member of the parent entry' do
          user = create(:user)
          entry = create(:entry)

          sign_in(user)
          put(:update, :entry_id => entry, :edit_lock => {:id => 'not_there_anymore'}, :format => :json)

          expect(response.status).to eq(403)
        end

        it 'requires authentication' do
          entry = create(:entry)

          put(:update, :entry_id => entry, :edit_lock => {:id => 'not_there_anymore'}, :format => :json)

          expect(response.status).to eq(401)
        end
      end

      context 'when locked by given lock' do
        it 'succeeds for member of the entry' do
          user = create(:user)
          entry = create(:entry, :with_member => user)
          edit_lock = entry.edit_lock.aquire(user)

          sign_in(user)
          put(:update, :entry_id => entry, :edit_lock => {:id => edit_lock.id})

          expect(response.status).to eq(204)
        end

        it 'keeps entry locked for the current user' do
          user = create(:user)
          entry = create(:entry, :with_member => user)
          edit_lock = entry.edit_lock.aquire(user)

          sign_in(user)
          put(:update, :entry_id => entry, :edit_lock => {:id => edit_lock.id})

          expect(entry.edit_lock).to be_held_by(user)
        end

        it 'requires the signed in user to be member of the parent entry' do
          user = create(:user)
          entry = create(:entry)
          edit_lock = entry.edit_lock.aquire(user)

          sign_in(user)
          put(:update, :entry_id => entry, :edit_lock => {:id => edit_lock.id}, :format => :json)

          expect(response.status).to eq(403)
        end

        it 'requires authentication' do
          entry = create(:entry)
          edit_lock = entry.edit_lock.aquire(create(:user))

          put(:update, :entry_id => entry, :edit_lock => {:id => edit_lock.id}, :format => :json)

          expect(response.status).to eq(401)
        end
      end

      context 'when lockeded by other user' do
        it 'responds with conflict' do
          user = create(:user)
          entry = create(:entry, :with_member => user)
          entry.edit_lock.aquire(create(:user))

          sign_in(user)
          put(:update, :entry_id => entry, :edit_lock => {:id => 'not_there_anymore'}, :format => :json)

          expect(response.status).to eq(409)
        end

        it 'does not break other users lock' do
          user = create(:user)
          other_user = create(:user)
          entry = create(:entry, :with_member => user)
          entry.edit_lock.aquire(other_user)

          sign_in(user)
          put(:update, :entry_id => entry, :edit_lock => {:id => 'not_there_anymore'}, :format => :json)

          expect(entry.edit_lock).to be_held_by(other_user)
        end
      end
    end

    describe '#destroy' do
      context 'when not locked' do
        it 'succeeds for member of the entry' do
          user = create(:user)
          entry = create(:entry, :with_member => user)

          sign_in(user)
          delete(:destroy, :entry_id => entry, :format => :json)

          expect(response.status).to eq(204)
        end
      end

      context 'when locked by current user' do
        it 'succeeds for member of the entry' do
          user = create(:user)
          entry = create(:entry, :with_member => user)
          edit_lock = entry.edit_lock.aquire(user)

          sign_in(user)
          delete(:destroy, :entry_id => entry, :format => :json)

          expect(response.status).to eq(204)
        end

        it 'releases lock' do
          user = create(:user)
          entry = create(:entry, :with_member => user)
          edit_lock = entry.edit_lock.aquire(user)

          sign_in(user)
          delete(:destroy, :entry_id => entry, :format => :json)

          expect(entry.reload.edit_lock).to be_blank
        end

        it 'requires authentication' do
          entry = create(:entry)
          edit_lock = entry.edit_lock.aquire(create(:user))

          delete(:destroy, :entry_id => entry, :format => :json)

          expect(response.status).to eq(401)
        end
      end

      context 'when lockeded by other user' do
        it 'does not break other users lock' do
          user = create(:user)
          other_user = create(:user)
          entry = create(:entry, :with_member => user)
          entry.edit_lock.aquire(other_user)

          sign_in(user)
          delete(:destroy, :entry_id => entry, :format => :json)

          expect(entry.edit_lock).to be_held_by(other_user)
        end
      end
    end
  end
end
