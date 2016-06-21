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

    context '#subject' do
      context 'No subject ID is set in session' do
        before do
          session[:subject_id] = nil
        end

        it 'returns nil' do
          expect(subject.subject).to be_nil
        end
      end

      context 'session has subject_id that does not represent a Subject' do
        before do
          session[:subject_id] = -1
        end

        it 'returns nil' do
          expect(subject.subject).to be_nil
        end
      end

      context 'Subject that is not functioning' do
        let(:current_subject) { create :subject, enabled: false }

        before do
          session[:subject_id] = current_subject.id
        end

        it 'returns nil' do
          expect(subject.subject).to be_nil
        end
      end

      context 'Subject is valid' do
        let(:current_subject) { create :subject }

        before do
          session[:subject_id] = current_subject.id
        end

        it 'returns subject' do
          expect(subject.subject).to eq(current_subject)
        end
      end
    end

    context '#ensure_authenticated as before_action' do
      subject { response }

      context 'No subject ID is set in session' do
        before do
          session[:subject_id] = nil
          get :an_action
        end

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

      context 'when request is session' do
        it 'POST request should not create a uri session' do
          post :an_action
          expect(session).not_to include(:return_url)
        end

        it 'GET request should not create a uri session' do
          get :an_action
          uri = URI.parse(session[:return_url])
          expect(uri.path).to eq('/anonymous/an_action')
          expect(uri.query).to be_blank
          expect(uri.fragment).to be_blank
        end

        it 'GET request should create a uri session including fragments' do
          get :an_action, params: { time: 1000 }
          uri = URI.parse(session[:return_url])

          expect(uri.path).to eq('/anonymous/an_action')
          expect(uri.query).to eq('time=1000')
          expect(uri.fragment).to be_blank
        end
      end
    end

    context '#ensure_access_checked as after_action' do
      before { session[:subject_id] = subject.id }

      RSpec.shared_examples 'ApplicationController base state' do
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

        include_examples 'ApplicationController base state'

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

        include_examples 'ApplicationController base state'

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

        include_examples 'ApplicationController base state'

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
