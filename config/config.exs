import Config

# Configure your application here
config :{{app_name}},
  env: config_env()

# Import environment specific config
if File.exists?("config/#{config_env()}.exs") do
  import_config "#{config_env()}.exs"
end
