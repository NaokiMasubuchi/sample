#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Twitter Analysis Runner — @ysk_motoyama
#
# Usage:
#   ruby runner.rb            # fetch new tweets & analyze
#   ruby runner.rb --force    # ignore since_id, re-fetch recent tweets
#
# Environment variables required:
#   ANTHROPIC_API_KEY       — Anthropic API key
#   TWITTER_BEARER_TOKEN    — X/Twitter API v2 bearer token
#
# Cron example (every day at 9am):
#   0 9 * * * cd /path/to/sample/twitter_analyzer && ruby runner.rb >> logs/runner.log 2>&1

require "fileutils"
require "json"
require "time"
require_relative "config"
require_relative "tweet_fetcher"
require_relative "analyzer"
require_relative "knowledge_store"

class Runner
  def initialize
    @fetcher = TweetFetcher.new
    @analyzer = Analyzer.new
    @store = KnowledgeStore.new
    @state = load_state
  end

  def run(force: false)
    run_at = Time.now
    puts "[#{run_at.iso8601}] Starting analysis for @#{Config::TARGET_USERNAME}"

    since_id = force ? nil : @state["last_tweet_id"]
    puts "  Fetching tweets (since_id: #{since_id || 'none'})..."

    tweets = @fetcher.fetch_new_tweets(since_id: since_id)

    if tweets.empty?
      puts "  No new tweets found. Exiting."
      return
    end

    puts "  Fetched #{tweets.size} tweets."
    puts "  Analyzing with Claude (adaptive thinking)..."

    analysis = @analyzer.analyze(tweets)

    if analysis.nil?
      puts "  Warning: analysis returned nil, saving raw report only."
    end

    @store.save_report(tweets, analysis, run_at: run_at)
    @store.save_knowledge(analysis, run_at: run_at)
    @store.update_tag_index

    # Update state with newest tweet id (tweets are returned newest-first)
    newest_id = tweets.map { |t| t[:id].to_i }.max.to_s
    save_state("last_tweet_id" => newest_id, "last_run" => run_at.iso8601)

    puts "  Done."
  end

  private

  def load_state
    return {} unless File.exist?(Config::STATE_FILE)
    JSON.parse(File.read(Config::STATE_FILE))
  rescue JSON::ParserError
    {}
  end

  def save_state(data)
    File.write(Config::STATE_FILE, JSON.pretty_generate(data))
  end
end

force = ARGV.include?("--force")
Runner.new.run(force: force)
