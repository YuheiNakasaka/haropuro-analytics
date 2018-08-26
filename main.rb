require "pry"
require "nokogiri"
require "open-uri"
require "csv"

puts "[#{Time.now.strftime('%Y-%m-%d %H:%M')}] Start #{__FILE__}"

SCHEME = 'https://'
DOMAIN = 'ameblo.jp'
MEMBERS = [
  {name: "宮崎由加", link: "/juicejuice-official/theme-10073622419.html"},
  {name: "金澤朋子", link: "/juicejuice-official/theme-10073622432.html"},
  {name: "高木紗友希", link: "/juicejuice-official/theme-10073622464.html"},
  {name: "宮本佳林", link: "/juicejuice-official/theme-10073622495.html"},
  {name: "植村あかり", link: "/juicejuice-official/theme-10073622506.html"},
  {name: "梁川奈々美", link: "/juicejuice-official/theme-10103223814.html"},
  {name: "梁川奈々美", link: "/countrygirls/theme-10094622016.html"},
  {name: "段原瑠々", link: "/juicejuice-official/theme-10103223818.html"},
  {name: "稲場愛香", link: "/juicejuice-official/theme-10106520232.html"},
  {name: "中西香菜", link: "/angerme-amerika/theme-10087142410.html"},
  {name: "竹内朱莉", link: "/angerme-amerika/theme-10087142424.html"},
  {name: "勝田里奈", link: "/angerme-amerika/theme-10087142415.html"},
  {name: "室田瑞希", link: "/angerme-ss-shin/theme-10087284995.html"},
  {name: "船木結", link: "/angerme-ss-shin/theme-10103225326.html"},
  {name: "船木結", link: "/countrygirls/theme-10094622018.html"},
  {name: "川村文乃", link: "/angerme-ss-shin/theme-10103225477.html"},
  {name: "佐々木莉佳子", link: "/angerme-ss-shin/theme-10087285029.html"},
  {name: "上国料萌", link: "/angerme-ss-shin/theme-10094584095.html"},
  {name: "笠原桃奈", link: "/angerme-ss-shin/theme-10097979200.html"},
  {name: "和田彩花", link: "/angerme-ayakawada/theme-10086857983.html"},
  {name: "山岸理子", link: "/tsubaki-factory/theme-10090188545.html"},
  {name: "小片りさ", link: "/tsubaki-factory/theme-10090188547.html"},
  {name: "新沼希空", link: "/tsubaki-factory/theme-10090188548.html"},
  {name: "谷本安美", link: "/tsubaki-factory/theme-10090188551.html"},
  {name: "岸本ゆめの", link: "/tsubaki-factory/theme-10090188555.html"},
  {name: "浅倉樹々", link: "/tsubaki-factory/theme-10090188560.html"},
  {name: "小野瑞穂", link: "/tsubaki-factory/theme-10098778223.html"},
  {name: "小野田紗栞", link: "/tsubaki-factory/theme-10098778228.html"},
  {name: "秋山眞緒", link: "/tsubaki-factory/theme-10098778236.html"},
  {name: "広瀬彩海", link: "/kobushi-factory/theme-10089023515.html"},
  {name: "野村みな美", link: "/kobushi-factory/theme-10089023524.html"},
  {name: "浜浦彩乃", link: "/kobushi-factory/theme-10089023588.html"},
  {name: "和田桜子", link: "/kobushi-factory/theme-10089023592.html"},
  {name: "井上玲音", link: "/kobushi-factory/theme-10089023603.html"},
  {name: "譜久村聖", link: "/morningmusume-9ki/theme-10059757620.html"},
  {name: "生田衣梨奈", link: "/morningmusume-9ki/theme-10059751724.html"},
  {name: "飯窪春菜", link: "/morningmusume-10ki/theme-10059753252.html"},
  {name: "石田亜佑美", link: "/morningmusume-10ki/theme-10059753284.html"},
  {name: "佐藤優樹", link: "/morningmusume-10ki/theme-10059753314.html"},
  {name: "小田さくら", link: "/morningmusume-10ki/theme-10068520081.html"},
  {name: "野中美希", link: "/mm-12ki/theme-10086725506.html"},
  {name: "牧野真莉愛", link: "/mm-12ki/theme-10086725508.html"},
  {name: "羽賀朱音", link: "/mm-12ki/theme-10086725549.html"},
  {name: "横山玲奈", link: "/morningm-13ki/theme-10101009109.html"},
  {name: "加賀楓", link: "/morningm-13ki/theme-10101156746.html"},
  {name: "森戸知沙希", link: "/morningm-13ki/theme-10103247869.html"},
  {name: "森戸知沙希", link: "/countrygirls/theme-10087903805.html"},
  {name: "山木梨沙", link: "/countrygirls/theme-10087903791.html"},
  {name: "小関舞", link: "/countrygirls/theme-10087903830.html"},
]

class Crawler
  def initialize(link:, threashold_time: "")
    @link = link
    @results = []
    @is_last = false
    @threashold_time = threashold_time
  end

  def run
    # タイトル,いいね数,コメント数,urlを取得する
    filter_elms(downloaded_document, "div", "data-uranus-component", "entryItemBody").each do |entry_body|
      result = base_result

      # 計測期間外のエントリまできたらbreakさせる
      raw_time = ""
      filter_elms(entry_body, "p", "data-uranus-component", "entryItemDatetime").each do |elm|
        if m = elm.text.match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
          raw_time = m[0]
        elsif m = elm.text.match(/(\d{4})年(\d{2})月(\d{2})日/) # アンジュルム対策
          raw_time = "#{m[1]}-#{m[2]}-#{m[3]}"
        end
      end
      created_at = Time.parse(raw_time)
      start_time = @threashold_time != "" ? Time.parse(@threashold_time) : Time.parse("#{Time.now.year}-#{Time.now.month}-01 00:00:00")
      result[:created_at] = created_at
      if start_time > created_at
        @is_last = true
        break
      end

      # タイトル,いいね数,コメント数,urlを取得する
      result[:title] = entry_body.css("h2").text
      result[:url]   = entry_body.css("h2 a").attribute("href").value
      filter_elms(entry_body, "dl", "data-uranus-component", "feedbackCounts").each do |dl|
        dds = dl.css("dd")
        if dds.size == 2
          result[:like_count] = dds.first.text.to_i
          result[:comment_count] = dds.last.text.to_i
        elsif dds.size == 3
          result[:like_count] = dds[0].text.to_i
          result[:comment_count] = dds[1].text.to_i
        end
      end
      @results << result
    end

    {data: @results, is_last: @is_last}
  end

  private
  def downloaded_document
    html = open(@link).read
    Nokogiri::HTML(html)
  end

  def base_result
    {
      title: "",
      url: "",
      like_count: 0,
      comment_count: 0,
      created_at: ""
    }
  end

  def filter_elms(doc, elm, atribute_name, attribute_value)
    doc.css(elm).select{|o| o.attribute(atribute_name).to_s == attribute_value}
  end
end

CSV.open("member_blog_data.tsv", "w", :col_sep => "\t") do |file|
  MEMBERS.each do |member|
    puts "#{member[:name]}"
    (1..5).each do |pageIndex|
      start_url  = pageIndex == 1 ? "#{SCHEME}#{DOMAIN}#{member[:link]}" : "#{SCHEME}#{DOMAIN}#{member[:link].sub(/theme-/, "theme#{pageIndex}-")}"
      crawler = Crawler.new(link: start_url, threashold_time: "2018-08-01 00:00:00")
      result  = crawler.run
      result[:data].each do |record|
        file.puts [member[:name], record[:title], record[:url], record[:created_at], record[:like_count], record[:comment_count]]
      end
      break if result[:is_last]
      sleep 3
    end
  end
end

puts "[#{Time.now.strftime('%Y-%m-%d %H:%M')}] End"
