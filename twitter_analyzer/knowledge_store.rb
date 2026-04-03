require "json"
require "time"
require_relative "config"

class KnowledgeStore
  def initialize(base_dir = Config::KNOWLEDGE_BASE)
    @base_dir = base_dir
    FileUtils.mkdir_p(@base_dir)
  end

  # Save full analysis report (all tweets + criticism)
  def save_report(tweets, analysis, run_at: Time.now)
    filename = "report_#{run_at.strftime('%Y%m%d_%H%M%S')}.md"
    path = File.join(@base_dir, filename)

    content = build_report(tweets, analysis, run_at)
    File.write(path, content)
    puts "  Report saved: #{filename}"
    path
  end

  # Save high-value knowledge to a dedicated stock file
  def save_knowledge(analysis, run_at: Time.now)
    return unless analysis

    stocked = analysis["tweets"]&.select { |t| t["worth_stocking"] }
    return if stocked.nil? || stocked.empty?

    filename = "knowledge_#{run_at.strftime('%Y%m%d_%H%M%S')}.md"
    path = File.join(@base_dir, filename)

    content = build_knowledge_doc(stocked, run_at)
    File.write(path, content)
    puts "  Knowledge stocked: #{stocked.size} items → #{filename}"
    path
  end

  # Update cumulative tag index
  def update_tag_index
    all_tags = {}
    Dir.glob(File.join(@base_dir, "knowledge_*.md")).each do |f|
      File.readlines(f).each do |line|
        next unless line.start_with?("**Tags:**")
        line.scan(/`([^`]+)`/).flatten.each do |tag|
          all_tags[tag] = (all_tags[tag] || 0) + 1
        end
      end
    end

    return if all_tags.empty?

    index_path = File.join(@base_dir, "TAG_INDEX.md")
    sorted = all_tags.sort_by { |_, v| -v }
    lines = ["# Tag Index\n\n_Auto-generated. Last updated: #{Time.now.iso8601}_\n\n"]
    lines += sorted.map { |tag, count| "- `#{tag}` (#{count})" }
    File.write(index_path, lines.join("\n"))
  end

  private

  def build_report(tweets, analysis, run_at)
    lines = []
    lines << "# Tweet Analysis Report — @#{Config::TARGET_USERNAME}"
    lines << "_Run at: #{run_at.iso8601} / #{tweets.size} tweets analyzed_\n"

    if analysis
      lines << "## Overall Summary"
      lines << analysis["batch_summary"].to_s
      lines << ""

      lines << "## Tweet-by-Tweet Criticism"
      (analysis["tweets"] || []).each do |ta|
        tweet = tweets.find { |t| t[:id] == ta["id"] }
        lines << "\n### [Score: #{ta['overall_score']}/5] #{ta['text_summary']}"
        lines << "#{ta['worth_stocking'] ? '**★ Stocked**' : '_(not stocked)_'}\n"
        lines << "> #{tweet[:text].gsub("\n", "\n> ")}" if tweet
        lines << ""
        lines << "| 観点 | 批評 |"
        lines << "|------|------|"
        c = ta["criticism"] || {}
        lines << "| 内容の質 | #{c['content_quality']} |"
        lines << "| 独自性   | #{c['originality']} |"
        lines << "| 実用性   | #{c['practicality']} |"
        lines << "| 論理性   | #{c['logic']} |"
        lines << "| 明確さ   | #{c['clarity']} |"
        lines << "| 信頼性   | #{c['reliability']} |"
      end
    else
      lines << "_Analysis unavailable_"
    end

    lines.join("\n")
  end

  def build_knowledge_doc(stocked, run_at)
    lines = []
    lines << "# Knowledge Stock — @#{Config::TARGET_USERNAME}"
    lines << "_Stocked at: #{run_at.iso8601}_\n"

    stocked.each do |ta|
      k = ta["knowledge"] || {}
      lines << "## #{ta['text_summary']} (Score: #{ta['overall_score']}/5)"
      lines << "**Tags:** #{Array(k['tags']).map { |t| "`#{t}`" }.join(' ')}"
      lines << ""
      lines << "**Insight:** #{k['insight']}"
      lines << ""
      lines << "**How to use:** #{k['actionable']}"
      lines << "\n---\n"
    end

    lines.join("\n")
  end
end
