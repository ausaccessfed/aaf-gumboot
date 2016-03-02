guard :bundler do
  watch('Gemfile')
  watch(/^.+\.gemspec/)
end

guard :rspec, cmd: 'bundle exec rspec' do
  watch(%r{/^spec\/.+_spec\.rb$/})
  watch(%r{/^lib\/gumboot\/shared_examples\/(.+)\.rb$/}) do |m|
    "spec/gumboot/#{m[1]}_spec.rb"
  end
  watch(%r{^spec/(dummy|support)/.+\.rb}) { 'spec' }
  watch('spec/spec_helper.rb') { 'spec' }
end

guard :rubocop do
  watch(/.+\.rb$/)
  watch(%r{/(?:.+\/)?\.rubocop\.yml$/}) { |m| File.dirname(m[0]) }
end
