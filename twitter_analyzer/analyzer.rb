require "anthropic"
require "json"
require_relative "config"

class Analyzer
  SYSTEM_PROMPT = <<~PROMPT
    あなたはツイート批評・ナレッジ抽出の専門家です。
    与えられたツイート群を以下の観点で**多角的・網羅的に批評**し、
    価値あるナレッジをストック用に整理してください。

    ## 批評の観点
    1. **内容の質・深さ** — 情報密度、専門性、表面的か本質的か
    2. **独自性・新規性** — 既知の情報か、独自の視点・発見があるか
    3. **実用性・応用可能性** — 読者がすぐに使える知識か
    4. **論理的一貫性** — 主張に根拠があるか、矛盾がないか
    5. **表現の明確さ** — 伝わりやすさ、曖昧さ、過度な断言
    6. **情報の信頼性** — 裏付けがあるか、推測が多いか

    ## 出力形式（JSON）
    {
      "batch_summary": "このバッチ全体の傾向・特徴（200字以内）",
      "tweets": [
        {
          "id": "ツイートID",
          "text_summary": "ツイートの要約（50字以内）",
          "criticism": {
            "content_quality": "内容の質批評",
            "originality": "独自性批評",
            "practicality": "実用性批評",
            "logic": "論理性批評",
            "clarity": "明確さ批評",
            "reliability": "信頼性批評"
          },
          "overall_score": 1〜5の整数（1=低価値、5=高価値）,
          "worth_stocking": true/false,
          "knowledge": {
            "insight": "抽出される核心的な知見（stocking対象のみ）",
            "tags": ["タグ1", "タグ2"],
            "actionable": "具体的にどう使えるか（stocking対象のみ）"
          }
        }
      ]
    }
  PROMPT

  def initialize
    @client = Anthropic::Client.new(api_key: Config.anthropic_api_key)
  end

  def analyze(tweets)
    return [] if tweets.empty?

    tweet_text = tweets.map.with_index(1) do |t, i|
      "[#{i}] ID:#{t[:id]} (#{t[:created_at]}) 👍#{t[:like_count]} RT#{t[:retweet_count]}\n#{t[:text]}"
    end.join("\n\n")

    response = @client.messages.create(
      model: :"claude-opus-4-6",
      max_tokens: 16000,
      thinking: { type: "adaptive" },
      system_: [{ type: "text", text: SYSTEM_PROMPT }],
      messages: [
        { role: "user", content: "以下のツイートを批評・分析してください。\n\n#{tweet_text}" }
      ]
    )

    text = response.content.find { |b| b.type == :text }&.text || ""
    json_str = text[/\{[\s\S]*\}/]
    json_str ? JSON.parse(json_str) : nil
  end
end
