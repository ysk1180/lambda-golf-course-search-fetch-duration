require 'google_maps_service'
require 'rakuten_web_service'
require 'aws-record'

class Duration
  include Aws::Record
  integer_attr :golf_course_id, hash_key: true
  integer_attr :duration1
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

def put_item(course_id, duration)
  duration = Duration.new
  duration.golf_course_id = course_id
  duration.duration1 = minutes
  duration.save
end

def lambda_handler(event:, context:)
  departure = '二子玉川駅'
  area_code = '8'

  RakutenWebService.configure do |c|
    c.application_id = ENV['RAKUTEN_APPID']
    c.affiliate_id = ENV['RAKUTEN_AFID']
  end

  courses = RakutenWebService::Gora::Course.search(areaCode: area_code)
  course_id = courses.first['golfCourseId']
  course_name = courses.first['golfCourseName']

  minutes = duration_minutes(departure, course_name)
  put_item(course_id, minutes)

  { statusCode: 200 }
end
