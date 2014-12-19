require 'gumboot/shared_examples/anonymous_controller'

RSpec.shared_examples 'Application controller' do
  context 'AAF shared implementation' do
    include_examples 'Anon controller'

    before do
      @routes.draw do
        get '/anonymous/an_action' => 'anonymous#an_action'
        get '/anonymous/bad_action' => 'anonymous#bad_action'
        get '/anonymous/public' => 'anonymous#public'
      end
    end

    it { is_expected.to respond_to(:subject) }

    context '#ensure_authenticated as before_action' do
      subject { response }

      context 'No subject ID is set in session' do
        before { get :an_action }

        it { is_expected.to have_http_status(:redirect) }
        it { is_expected.to redirect_to('/auth/login') }
      end

      context 'session has subject_id that does not represent a Subject' do
        before do
          session[:subject_id] = -1
          get :an_action
        end

        it { is_expected.to have_http_status(:unauthorized) }
        it { is_expected.to render_template('errors/unauthorized') }

        it 'resets the session' do
          expect(session[:subject_id]).to be_nil
        end
      end

      context 'Subject that is not functioning' do
        let(:current_subject) { create :subject, enabled: false }

        before do
          session[:subject_id] = current_subject.id
          get :an_action
        end

        it { is_expected.to have_http_status(:unauthorized) }
        it { is_expected.to render_template('errors/unauthorized') }

        it 'resets the session' do
          expect(session[:subject_id]).to be_nil
        end
      end
    end

    context '#ensure_access_checked as after_action' do
      before { session[:subject_id] = subject.id }

      RSpec.shared_examples 'base state' do
        it 'fails request to incorrectly implemented action' do
          msg = 'No access control performed by AnonymousController#bad_action'
          expect { get :bad_action }.to raise_error(msg)
        end

        it 'completes request to a public action' do
          get :public
          expect(response).to have_http_status(:ok)
        end
      end

      context 'subject without permissions' do
        subject(:subject) { create :subject }

        include_examples 'base state'

        it 'has no permissions' do
          expect(subject.permissions).to eq([])
        end

        context 'the request does not complete' do
          before { get :an_action }
          it 'should respond with status code :forbidden (403)' do
            expect(response).to have_http_status(:forbidden)
          end
          it 'renders forbidden template' do
            expect(response).to render_template('errors/forbidden')
          end
        end
      end

      context 'subject with invalid permissions' do
        subject(:subject) do
          create :subject, :authorized, permission: 'invalid:permission'
        end

        include_examples 'base state'

        it 'has an invalid permission' do
          expect(subject.permissions).to eq(['invalid:permission'])
        end

        context 'the request does not complete' do
          before { get :an_action }
          it 'should respond with status code :forbidden (403)' do
            expect(response).to have_http_status(:forbidden)
          end
          it 'renders forbidden template' do
            expect(response).to render_template('errors/forbidden')
          end
        end
      end

      context 'subject with valid permission' do
        subject(:subject) do
          create :subject, :authorized, permission: 'required:permission'
        end

        include_examples 'base state'

        it 'has a valid permission' do
          expect(subject.permissions).to eq(['required:permission'])
        end

        it 'completes request after permissions checked' do
          get :an_action
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
