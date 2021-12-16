
## Testing guide

Ensure the test passes before submitting a Pull Request,

Currently this gem supports ActiveRecord 4.1, 5.0, 6.0 and 7.0, ensure the test works across these ActiveRecord version.

1. Run `bundle exec appraisal` to generate gemfiles required to support different Active Record version
2. Run `bundle exec appraisal rspec` to run test across different Active Record version
3. Ensure all of them passes

Thanks!