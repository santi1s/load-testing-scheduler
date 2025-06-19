#!/usr/bin/env ruby
# frozen_string_literal: true

require 'time'

class ScheduleValidator
  BUFFER_MINUTES = 30

  def validate_time_slot(requested_start, duration_minutes, _team, schedules = nil)
    schedules ||= []

    requested_start = Time.parse(requested_start) if requested_start.is_a?(String)
    requested_end = requested_start + (duration_minutes * 60)

    # Add buffer time
    buffered_start = requested_start - (BUFFER_MINUTES * 60)
    buffered_end = requested_end + (BUFFER_MINUTES * 60)

    conflicts = schedules.select do |schedule|
      schedule_start = Time.parse(schedule['datetime'])
      schedule_end = schedule_start + (schedule['duration'] * 60)

      # Check for overlap with buffer
      buffered_start < schedule_end && buffered_end > schedule_start
    end

    if conflicts.any?
      conflict_details = conflicts.map do |c|
        "#{c['team']} (#{c['datetime']} - #{c['duration']}min)"
      end.join(', ')

      raise "Time slot conflicts with existing tests: #{conflict_details}"
    end

    # Validate business hours (optional)
    validate_business_hours(requested_start, requested_end)

    # Validate maximum duration
    validate_duration(duration_minutes)

    true
  end

  private

  def validate_business_hours(start_time, end_time)
    # Optional: Restrict to business hours (9 AM - 6 PM UTC, weekdays)
    start_time.hour
    end_time.hour
    start_time.wday

    # Allow tests outside business hours for now
    # Uncomment to enforce business hours:
    # if weekday == 0 || weekday == 6 # Weekend
    #   raise "Load tests not allowed on weekends"
    # end
    #
    # if start_hour < 9 || end_hour > 18
    #   raise "Load tests must be scheduled between 9 AM and 6 PM UTC"
    # end
  end

  def validate_duration(duration_minutes)
    max_duration = 4 * 60 # 4 hours in minutes

    raise "Test duration cannot exceed #{max_duration / 60} hours" if duration_minutes > max_duration

    return unless duration_minutes < 15

    raise 'Test duration must be at least 15 minutes'
  end
end