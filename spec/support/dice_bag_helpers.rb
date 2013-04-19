module Support
  module DiceBagHelpers
    def run_dice_bag_tasks(env_vars, template_path)
      directory = File.join(DiceBag::Project.root, template_path)
      Dir::mkdir(directory) unless Dir.exists?(directory)
      
      # Remove existing crichton.yml from a previous run so overwrite confirmation doesn't appear.
      system("rm #{template_path}/crichton.yml") if File.exists?(File.join(directory, 'crichton.yml'))

      ::Rake::Task['config:generate_all'].invoke
      system("bundle exec rake config:file[\"#{template_path}/crichton.yml.dice\"] #{env_var_portion(env_vars)}")
    end

    private
    def env_var_portion(env_vars)
      env_vars.inject('') { |s, (k, v)| s << "#{k.upcase}=#{v} " }
    end
  end
end
