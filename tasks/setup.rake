namespace :demo_service do

  desc 'Runs alps profile generation and setup rake tasks for Crichton demo service'
  task :setup do
    
    cd 'spec/integration/crichton-demo-service'  do
      sh 'bundle exec rake alps:generate_profiles'
      sh 'bundle exec rake setup'
    end

  end

end

