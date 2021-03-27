class Activity < ApplicationRecord
  belongs_to :user
  belongs_to :import, optional: true
  default_scope { order(date: :asc, order: :asc) }

  RUN = "Run"
  OTHER = "Other"

  def match_or_create
    match = Activity.where(date: self.date, user: self.user).find { |a| self.match?(a) }
    if match && match.id == self.id
      nil
    elsif !match || (match && match.import)
      self.save!
    elsif !match.import
      match.import = self.import
      match.data['completed'] = true
      match.save!
    else
      nil
    end
  end

  def self.from_strava_activity(import)
    activity = import.data.deep_symbolize_keys
    type =
      if activity[:type] === RUN
        RUN
      else
        OTHER
      end

    date = Date.parse(activity[:start_date_local]).to_s
    description = activity[:name]
    duration = activity[:moving_time]
    data =
      if type === RUN
        pace = to_seconds_per_mile(activity[:average_speed])
        { type: type, pace: pace, duration: duration, completed: true }
      else
        { type: type, duration: duration, completed: true }
      end

    if activity[:laps] then
      data[:laps] = parse_strava_laps(activity[:laps])
    end

    activity_hash =
      { id: "#{activity[:id].to_s}",
        date: date,
        description: description,
        data: data,
        import: import,
        user: import.user }

    Activity.new(activity_hash)
  end

  def run?
    case self.data['type']
    when Activity::RUN
      true
    else
      false
    end
  end

  def match?(activity)
    return true if self.id == activity.id

    same_date = self.date == activity.date

    same_type = self.run? && activity.run? || (!self.run? && !activity.run?)
    ten_minutes = 10 * 60
    same_duration =
      if self.data['duration'] && activity.data['duration']
        (self.data['duration'] - activity.data['duration']).abs < ten_minutes
      else
        true
      end

    same_date && same_type && same_duration
  end

  private

  def self.to_seconds_per_mile(meters_per_second)
    (1609.3 / meters_per_second).round
  end

  def self.parse_strava_laps(laps)
    laps.map do |lap|
      { type: RUN,
        pace: to_seconds_per_mile(lap[:average_speed]),
        duration: lap[:moving_time],
        completed: true
      }
    end
  end

end
