RSpec.shared_examples 'Anon controller' do
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
end
