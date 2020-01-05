require 'google_maps_service'
require 'rakuten_web_service'
require 'aws-record'

class Duration
  include Aws::Record
  integer_attr :golf_course_id, hash_key: true
  integer_attr :duration1
  integer_attr :duration2
  integer_attr :duration3
  integer_attr :duration4
  integer_attr :duration5
  integer_attr :duration6
  integer_attr :prefecture
end

module Area
  CODE = '14' # ここにエリアコードを入れる 8:茨城県,11:埼玉県,12:千葉県,13:東京都,14:神奈川県
end

module Departure
  DEPARTURES = {
  #  1 => '二子玉川駅',
  #  2 => '吉祥寺駅',
  #  3 => '赤羽駅',
  #  4 => '錦糸町駅',
  #  5 => '川崎駅'
    6 => '川越駅'
  }
end

def duration_minutes(departure, destination)
  gmaps = GoogleMapsService::Client.new(key: ENV['GOOGLE_MAP_API_KEY'])
  routes = gmaps.directions(
    departure,
    destination,
  )
  duration_seconds = routes.first[:legs][0][:duration][:value]
  duration_seconds / 60
end

def put_item(course_id, durations)
#  duration = Duration.new
#  duration.golf_course_id = course_id
#  duration.duration1 = durations.fetch(1)
#  duration.duration2 = durations.fetch(2)
#  duration.duration3 = durations.fetch(3)
#  duration.duration4 = durations.fetch(4)
#  duration.duration5 = durations.fetch(5)
#  duration.prefecture = Area::CODE
  duration = Duration.find(golf_course_id: course_id)
  return unless duration
  duration.duration6 = durations.fetch(6)
  duration.save
end

def lambda_handler(event:, context:)
  RakutenWebService.configure do |c|
    c.application_id = ENV['RAKUTEN_APPID']
    c.affiliate_id = ENV['RAKUTEN_AFID']
  end

  1.upto(100) do |page|
    courses = RakutenWebService::Gora::Course.search(areaCode: Area::CODE, page: page)
    courses.each do |course|
      course_id = course['golfCourseId']
      course_name = course['golfCourseName']
      next if course_name.include?('レッスン') # ゴルフ場以外の情報をこれでスキップしてる

      durations = {}
      Departure::DEPARTURES.each do |duration_id, departure|
        durations.store(duration_id, duration_minutes(departure, course_name))
      end
      put_item(course_id, durations)
    end
    break unless courses.has_next_page?
  end

  { statusCode: 200 }
end
