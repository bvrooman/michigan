# frozen_string_literal: true

require 'logger'

module Michigan
  class Config
    @default_config = {
      logger: Logger.new($stdout),
      schemas_path: ''
    }
    @allowed_config_keys = @default_config.keys

    class << self
      attr_reader :default_config, :allowed_config_keys
    end

    attr_reader :config

    def initialize
      @config = OpenStruct.new Config.default_config
    end

    def configure(options)
      options.each do |key, value|
        @config.send("#{key.to_sym}=", value) if Config.allowed_config_keys.include? key.to_sym
      end
    end
  end

  def self.config
    @config ||= Config.new.config
  end

  def self.default_configuration
    @default_configuration || Config.new.config
  end
end
