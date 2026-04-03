require "httparty"
require "json"
require_relative "config"

class TweetFetcher
  BASE_URL = "https://api.twitter.com/2"

  def initialize(bearer_token = Config.twitter_bearer_token)
    @bearer_token = bearer_token
    @headers = { "Authorization" => "Bearer #{@bearer_token}" }
  end

  # Returns array of tweet hashes: { id:, text:, created_at:, public_metrics: }
  def fetch_new_tweets(since_id: nil)
    user_id = resolve_user_id(Config::TARGET_USERNAME)
    return [] unless user_id

    params = {
      max_results: Config::MAX_TWEETS,
      "tweet.fields" => "created_at,public_metrics,entities",
      exclude: "retweets,replies"
    }
    params[:since_id] = since_id if since_id

    response = get("#{BASE_URL}/users/#{user_id}/tweets", params)
    data = response.dig("data")
    return [] if data.nil? || data.empty?

    data.map do |t|
      {
        id: t["id"],
        text: t["text"],
        created_at: t["created_at"],
        like_count: t.dig("public_metrics", "like_count") || 0,
        retweet_count: t.dig("public_metrics", "retweet_count") || 0,
        reply_count: t.dig("public_metrics", "reply_count") || 0
      }
    end
  end

  private

  def resolve_user_id(username)
    response = get("#{BASE_URL}/users/by/username/#{username}", { "user.fields" => "id" })
    response.dig("data", "id")
  end

  def get(url, params = {})
    response = HTTParty.get(url, headers: @headers, query: params)
    unless response.success?
      raise "Twitter API error #{response.code}: #{response.body}"
    end
    JSON.parse(response.body)
  end
end
