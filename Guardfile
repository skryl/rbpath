# A sample Guardfile
# More info at https://github.com/guard/guard#readme

notification :growl

guard :minitest do
  watch(%r{^test/test_(.*)\.rb})
  watch(%r{^lib/(.*/)?([^/]+)\.rb})     { |m| "test/test_#{m[2]}.rb" }
  watch(%r{^test/test_helper\.rb})      { 'test' }
end
