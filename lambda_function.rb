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
end

module Departure
  Departures = {
    1 => '二子玉川駅',
    2 => '吉祥寺駅',
    3 => '赤羽駅',
    4 => '錦糸町駅',
    5 => '川崎駅'
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
  duration = Duration.new
  duration.golf_course_id = course_id
  duration.duration1 = durations.fetch(1)
  duration.duration2 = durations.fetch(2)
  duration.duration3 = durations.fetch(3)
  duration.duration4 = durations.fetch(4)
  duration.duration5 = durations.fetch(5)
  duration.save
end

def lambda_handler(event:, context:)
  area_code = '8'

  RakutenWebService.configure do |c|
    c.application_id = ENV['RAKUTEN_APPID']
    c.affiliate_id = ENV['RAKUTEN_AFID']
  end

  courses = RakutenWebService::Gora::Course.search(areaCode: area_code)
  course_id = courses.first['golfCourseId']
  course_name = courses.first['golfCourseName']

  durations = {}
  Departure::Departures.each do |duration_id, departure|
    durations.store(duration_id, duration_minutes(departure, course_name))
  end
  put_item(course_id, durations)

  { statusCode: 200 }
end
