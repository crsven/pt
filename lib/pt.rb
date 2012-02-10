require 'rubygems'

module PT
  class InputError < StandardError; end
  VERSION = '0.5'

  GLOBAL_CONFIG_PATH = ENV['HOME'] + "/.pt"
  LOCAL_CONFIG_PATH = Dir.pwd + '/.pt'

  # Config
  def load_global_config
    config = YAML.load(File.read(GLOBAL_CONFIG_PATH)) rescue {}
    if config.empty?
      message "I can't find info about your Pivotal Tracker account in #{GLOBAL_CONFIG_PATH}"
      while !config[:api_number] do
        config[:email] = ask "What is your email?"
        password = ask_secret "And your password? (won't be displayed on screen)"
        begin
          config[:api_number] = PT::Client.get_api_token(config[:email], password)
        rescue PT::InputError => e
          error e.message + " Please try again."
        end
      end
      congrats "Thanks!",
               "Your API id is " + config[:api_number],
               "I'm saving it in #{GLOBAL_CONFIG_PATH} to don't ask you again."
      save_config(config, GLOBAL_CONFIG_PATH)
    end
    config
  end

  def load_local_config
    check_local_config_path
    config = YAML.load(File.read(LOCAL_CONFIG_PATH)) rescue {}
    if config.empty?
      message "I can't find info about this project in #{LOCAL_CONFIG_PATH}"
      projects = PT::ProjectTable.new(@client.get_projects)
      project = select("Please select the project for the current directory", projects)
      config[:project_id], config[:project_name] = project.id, project.name
      project = @client.get_project(project.id)
      membership = @client.get_membership(project, @global_config[:email])
      config[:user_name], config[:user_id], config[:user_initials] = membership.name, membership.id, membership.initials
      congrats "Thanks! I'm saving this project's info",
               "in #{LOCAL_CONFIG_PATH}: remember to .gitignore it!"
      save_config(config, LOCAL_CONFIG_PATH)
    end
    config
  end

  def check_local_config_path
    if GLOBAL_CONFIG_PATH == LOCAL_CONFIG_PATH
      error("Please execute .pt inside your project directory and not in your home.")
      exit
    end
  end

  def save_config(config, path)
    File.new(path, 'w') unless File.exists?(path)
    File.open(path, 'w') {|f| f.write(config.to_yaml) }
  end

  def client
    global_config = PT.load_global_config
    client = PT::Client.new(global_config[:api_number])
  end

  def project
    local_config = PT.load_local_config
    project = client.get_project(local_config[:project_id])
  end

  module_function :load_global_config, :load_local_config, :check_local_config_path, :save_config, :client, :project
end

require 'pt/client'
require 'pt/data_row'
require 'pt/data_table'
require 'pt/ui'
require 'pt/curses_interface'
