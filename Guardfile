guard :bundler do
  watch('Gemfile')
  watch(/^.+\.gemspec/)
end

guard :rspec, cmd: 'bundle exec rspec' do
  watch(/^spec\/.+_spec\.rb$/)
  watch(/^lib\/gumboot\/shared_examples\/(.+)\.rb$/) { |m| "spec/gumboot/#{m[1]}_spec.rb" }
  watch(%r{^spec/(dummy|support)/.+\.rb}) { 'spec' }
  watch('spec/spec_helper.rb') { 'spec' }
end

guard :rubocop do
  watch(/.+\.rb$/)
  watch(/(?:.+\/)?\.rubocop\.yml$/) { |m| File.dirname(m[0]) }
end
