module Config
  TARGET_USERNAME   = "ysk_motoyama"
  STATE_FILE        = File.join(__dir__, ".state.json")
  KNOWLEDGE_BASE    = File.join(__dir__, "knowledge_base")

  def self.anthropic_api_key
    ENV.fetch("ANTHROPIC_API_KEY") { raise "ANTHROPIC_API_KEY is not set" }
  end

  def self.twitter_bearer_token
    ENV.fetch("TWITTER_BEARER_TOKEN") { raise "TWITTER_BEARER_TOKEN is not set" }
  end

  # How many tweets to fetch per run (max 100)
  MAX_TWEETS = 20
end
