import Config

# Configure your application here
config :tracer,
  env: config_env()

# Import environment specific config
if File.exists?("config/#{config_env()}.exs") do
  import_config "#{config_env()}.exs"
end
