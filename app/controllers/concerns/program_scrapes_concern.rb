require 'selenium-webdriver'

module ProgramScrapesConcern

extend ActiveSupport::Concern

  def program_information_acquisition
    set_scrape
    #execution_scrape
    programs_save
  end

  def set_scrape
    @wait_time = 3
    @timeout = 5

    # Seleniumの初期化
    # class ref: https://www.rubydoc.info/gems/selenium-webdriver/Selenium/WebDriver/Chrome
    Selenium::WebDriver.logger.output = File.join("./", "selenium.log")
    Selenium::WebDriver.logger.level = :warn

    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')
    driver = Selenium::WebDriver.for :chrome, options: options
    driver.manage.timeouts.implicit_wait = @timeout

    # 警告：割り当てられているが未使用の変数 -wait
    wait = Selenium::WebDriver::Wait.new(timeout: @wait_time)

    # Yahoo番組表を開く
    sleep(rand(5))
    driver.get('https://tv.yahoo.co.jp/listings')

    # 番組表からurl一件ずつ取得
    @programs = []
    elements = driver.find_elements(:class, "listingTablesTextLink")
    @urls = elements.map { |element| element.attribute('href') }
    @urls.first(1).each do |url|
    driver.navigate.to(url)

    sleep(rand(5))

    cur_url = driver.current_url
    p cur_url

    # 番組データを取得
    #binding.pry
    begin
    title = driver.find_element(:class, "programRatingContentTitle").text
    rescue Selenium::WebDriver::Error::NoSuchElementError
    title = ""
    end

    begin
    second_title = driver.find_element(:class, "programVideoContentTitleText").text
    rescue Selenium::WebDriver::Error::NoSuchElementError
    second_title = ""
    end

    begin
    cast = driver.find_element(:xpath, "//h3[contains(text(), '出演者')]/following-sibling::p[1]").text
    rescue Selenium::WebDriver::Error::NoSuchElementError
    cast = "※ 情報がありません"
    end

    begin
    channel = driver.find_element(:class, "channelText").text
    rescue Selenium::WebDriver::Error::NoSuchElementError
    channel = ""
    end

    begin
    category = driver.find_element(:class, "programOtherDataListText").text
    rescue Selenium::WebDriver::Error::NoSuchElementError
    category = ""
    end

    # 取得元のdatetimeの表記が12h制なのでdateとtimeを分けて取得　dateは属性値からdate情報のみ抽出、timeはtextから取得
    # start_datetime
    begin
    start_date = driver.find_element(:xpath, "//p[contains(text(), '放送日時・内容')]/following-sibling::div[1]/time[1]").attribute("datetime").slice(0..9)
    rescue Selenium::WebDriver::Error::NoSuchElementError
    start_date = ""
    end

    begin
    start_time = driver.find_element(:xpath, "//p[contains(text(), '放送日時・内容')]/following-sibling::div[1]//span[3]").text
    rescue Selenium::WebDriver::Error::NoSuchElementError
    start_time = ""
    end

    # end_datetime
    begin
    end_date = driver.find_element(:xpath, "//p[contains(text(), '放送日時・内容')]/following-sibling::div[1]/time[2]").attribute("datetime")
    rescue Selenium::WebDriver::Error::NoSuchElementError
    end_date = ""
    end

    begin
    end_time = driver.find_element(:class, "scheduleTextTimeEnd").text
    rescue Selenium::WebDriver::Error::NoSuchElementError
    end_time = ""
    end

    # 取得したdate、timeを結合、タイムゾーンをJSTに変更
      # 放送開始時間
      year, month, day = start_date.split('-').map(&:to_i)
      hour, minute = start_time.split(':').map(&:to_i)
      start_datetime = Time.zone.local(year, month, day, hour, minute)
      # 放送終了時間
      year, month, day = end_date.split('-').map(&:to_i)
      hour, minute = end_time.split(':').map(&:to_i)
      end_datetime = Time.zone.local(year, month, day, hour, minute)

      # 曜日取得
      by_weekday = start_datetime.wday

      # 放送時間に含まれるか判断
      status = if Time.zone.now <= start_datetime
        "放送予定"
      elsif Time.zone.now.between?(start_datetime, end_datetime)
        "放送中"
      elsif end_datetime <= Time.zone.now
        "放送終了"
      end



    @programs.push( 'title': title, 'second_title': second_title, 'cast': cast, 'channel': channel, 'category': category,
    'start_datetime': start_datetime, 'end_datetime': end_datetime, 'status': status, 'by_weekday': by_weekday )

    p @programs


    end
    # ドライバーを閉じる
    driver.quit
    @programs


  end

  def programs_save
    # データをデータベースに保存
    @programs.each do |program|
      @program = Program.new
      @program.assign_attributes(program)
      @program.save
    end


    # for i in 0..@titles.count
    # program = Program.new
    # program.title = @titles[i]
    # program.date = @dates[i]
    # program.save

    # 開始時刻
    # 時間
    # hour = datetime.hour
    # # 分
    # minute = datetime.minute

    # # 日付
    # year = datetime.year
    # month = datetime.month
    # date = datetime.day

    # # 曜日 （0：日 〜 6：土）
    # by_weekday = datetime.wday
  end
end