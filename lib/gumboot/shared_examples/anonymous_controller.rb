# frozen_string_literal: true

RSpec.shared_examples 'Anon controller' do
  controller(described_class) do
    def an_action
      check_access!('required:permission')
      head :ok
    end

    def bad_action
      head :ok
    end

    def public
      public_action
      head :ok
    end
  end
end
