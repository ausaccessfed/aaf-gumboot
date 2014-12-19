require 'gumboot/shared_examples/anonymous_controller'

RSpec.shared_examples 'API base controller' do
  context 'AAF shared implementation' do
    include_examples 'Anon controller'

    before do
      @routes.draw do
        get '/anonymous/an_action' => 'api/api#an_action'
        get '/anonymous/bad_action' => 'api/api#bad_action'
        get '/anonymous/public' => 'api/api#public'
      end
    end

    it { is_expected.to respond_to(:subject) }

    context '#before_action' do
      subject { response }
      let(:json) { JSON.parse(subject.body) }

      context 'no x509 header set by nginx' do
        before { get :an_action }

        it { is_expected.to have_http_status(:unauthorized) }

        context 'json within response' do
          it 'has a message' do
            expect(json['message']).to eq('SSL client failure.')
          end
          it 'has an error' do
            expect(json['error']).to eq('Subject DN')
          end
        end
      end

      context 'invalid x509 header set by nginx' do
        before do
          request.env['HTTP_X509_DN'] = "Z=#{Faker::Lorem.word}"
          get :an_action
        end

        it { is_expected.to have_http_status(:unauthorized) }
        context 'json within response' do
          it 'has a message' do
            expect(json['message']).to eq('SSL client failure.')
          end
          it 'has an error' do
            expect(json['error']).to eq('Subject DN invalid')
          end
        end
      end

      context 'without a CN component to DN' do
        before do
          request.env['HTTP_X509_DN'] = "O=#{Faker::Lorem.word}"
          get :an_action
        end

        it { is_expected.to have_http_status(:unauthorized) }
        context 'json within response' do
          it 'has a message' do
            expect(json['message']).to eq('SSL client failure.')
          end
          it 'has an error' do
            expect(json['error']).to eq('Subject CN invalid')
          end
        end
      end

      context 'with a CN that does not represent an APISubject' do
        before do
          request.env['HTTP_X509_DN'] = "CN=#{Faker::Lorem.word}/" \
                                        "O=#{Faker::Lorem.word}"
          get :an_action
        end

        it { is_expected.to have_http_status(:unauthorized) }
        context 'json within response' do
          it 'has a message' do
            expect(json['message']).to eq('SSL client failure.')
          end
          it 'has an error' do
            expect(json['error']).to eq('Subject invalid')
          end
        end
      end

      context 'with an APISubject that is not functioning' do
        let(:api_subject) { create :api_subject, enabled: false }

        before do
          request.env['HTTP_X509_DN'] = "CN=#{api_subject.x509_cn}/" \
                                        "O=#{Faker::Lorem.word}"
          get :an_action
        end

        it { is_expected.to have_http_status(:unauthorized) }
        context 'json within response' do
          it 'has a message' do
            expect(json['message']).to eq('SSL client failure.')
          end
          it 'has an error' do
            expect(json['error']).to eq('Subject not functional')
          end
        end
      end
    end

    context '#after_action' do
      subject(:api_subject) { create :api_subject }
      let(:json) { JSON.parse(response.body) }

      before do
        request.env['HTTP_X509_DN'] = "CN=#{api_subject.x509_cn}/DC=example"
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

        context 'the request does not complete' do
          before { get :an_action }
          it 'should respond with status code :forbidden (403)' do
            expect(response).to have_http_status(:forbidden)
          end
          it 'recieves a json message' do
            expect(json['message'])
              .to eq('The request was understood but explicitly denied.')
          end
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

        context 'the request does not complete' do
          before { get :an_action }
          it 'should respond with status code :forbidden (403)' do
            expect(response).to have_http_status(:forbidden)
          end
          it 'recieves a json message' do
            expect(json['message'])
              .to eq('The request was understood but explicitly denied.')
          end
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
