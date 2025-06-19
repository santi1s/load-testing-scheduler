#!/usr/bin/env ruby
# frozen_string_literal: true

require 'time'

# Validates load test scheduling constraints and conflicts
class ScheduleValidator
  BUFFER_MINUTES = 30

  def validate_time_slot(requested_start, duration_minutes, _team, schedules = nil)
    schedules ||= []
    time_range = parse_time_range(requested_start, duration_minutes)
    
    check_schedule_conflicts(time_range, schedules)
    validate_business_hours(time_range[:start], time_range[:end])
    validate_duration(duration_minutes)
    
    true
  end

  private

  def parse_time_range(requested_start, duration_minutes)
    start_time = requested_start.is_a?(String) ? Time.parse(requested_start) : requested_start
    end_time = start_time + (duration_minutes * 60)
    
    {
      start: start_time,
      end: end_time,
      buffered_start: start_time - (BUFFER_MINUTES * 60),
      buffered_end: end_time + (BUFFER_MINUTES * 60)
    }
  end

  def check_schedule_conflicts(time_range, schedules)
    conflicts = schedules.select do |schedule|
      schedule_start = Time.parse(schedule['datetime'])
      schedule_end = schedule_start + (schedule['duration'] * 60)

      # Check for overlap with buffer
      time_range[:buffered_start] < schedule_end && time_range[:buffered_end] > schedule_start
    end

    return unless conflicts.any?

    conflict_details = conflicts.map do |c|
      "#{c['team']} (#{c['datetime']} - #{c['duration']}min)"
    end.join(', ')

    raise "Time slot conflicts with existing tests: #{conflict_details}"
  end

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
