desc 'Sets up the application'
task :setup do
  Rake::Task['config:deploy'].invoke
  Rake::Task['build'].invoke
  Rake::Task['load:resource_descriptor'].invoke
end

desc 'Builds the database'
task :build => :environment do
  Rake::Task['db:drop'].invoke rescue nil
  Rake::Task['db:create'].invoke
  Rake::Task['db:migrate'].invoke
  Rake::Task['db:seed'].invoke
end
