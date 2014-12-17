RSpec.shared_examples 'API base controller' do
  context 'API Base Controller' do
    controller(described_class) do
      def an_action
        check_access!('required:permission')
        render nothing: true
      end

      def bad_action
        render nothing: true
      end

      def public
        public_action
        render nothing: true
      end
    end

    before do
      @routes.draw do
        get '/anonymous/an_action' => 'api/api#an_action'
        get '/anonymous/bad_action' => 'api/api#bad_action'
        get '/anonymous/public' => 'api/api#public'
      end
    end

    it 'is extended by anon controller' do
      expect(controller).to be_a_kind_of(described_class)
    end

    context '#after_action' do
      subject(:api_subject) { create :api_subject }

      before do
        request.env['HTTP_X509_DN'] = api_subject.x509_dn
      end

      RSpec.shared_examples 'base state' do
        it 'fails request to incorrectly implemented action' do
          msg = 'No access control performed by API::APIController#bad_action'
          expect { get :bad_action }.to raise_error(msg)
        end

        it 'completes request to a public action' do
          get :public
          expect(response).to have_http_status(:ok)
        end
      end

      context 'subject without permissions' do
        include_examples 'base state'

        it 'has no permissions' do
          expect(api_subject.permissions).to eq([])
        end

        it 'fails request when permissions checked' do
          get :an_action
          expect(response).to have_http_status(:forbidden)
        end
      end

      context 'subject with invalid permissions' do
        subject(:api_subject) do
          create :api_subject, :authorized, permission: 'invalid:permission'
        end

        include_examples 'base state'

        it 'has an invalid permission' do
          expect(api_subject.permissions).to eq(['invalid:permission'])
        end

        it 'fails request when permissions checked' do
          get :an_action
          expect(response).to have_http_status(:forbidden)
        end
      end

      context 'subject with valid permission' do
        subject(:api_subject) do
          create :api_subject, :authorized, permission: 'required:permission'
        end

        include_examples 'base state'

        it 'has a valid permission' do
          expect(api_subject.permissions).to eq(['required:permission'])
        end

        it 'completes request after permissions checked' do
          get :an_action
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
