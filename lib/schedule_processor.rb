#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'time'

class ScheduleProcessor
  SCHEDULE_FILE = 'config/schedules.json'
  BUFFER_MINUTES = 30

  def initialize(schedule_file = SCHEDULE_FILE)
    @schedule_file = schedule_file
  end

  def process_current_schedule
    schedules = load_schedules
    current_time = Time.now.utc
    
    active_tests = find_active_tests(schedules, current_time)
    
    if active_tests.any?
      puts "Active tests found: #{active_tests.size}"
      active_tests.each { |test| execute_test(test) }
      cleanup_completed_tests(schedules, current_time)
      save_schedules(schedules)
      return 0 # Success
    else
      puts "No active tests scheduled for current time"
      return 1 # No tests to run
    end
  end

  def validate_time_slot(requested_start, duration_minutes, team, schedules = nil)
    schedules ||= load_schedules
    
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

  def add_schedule(datetime, team, duration, test_type, contact, options = {})
    schedules = load_schedules
    
    # Validate the time slot
    validate_time_slot(datetime, duration, team, schedules)
    
    new_schedule = {
      'datetime' => datetime,
      'team' => team,
      'duration' => duration,
      'test_type' => test_type,
      'contact' => contact,
      'slack_channel' => options[:slack_channel],
      'app_version' => options[:app_version],
      'expected_load' => options[:expected_load],
      'priority' => options[:priority] || 'P2',
      'status' => 'scheduled',
      'created_at' => Time.now.utc.iso8601
    }
    
    # Insert in chronological order
    insert_position = schedules.find_index do |schedule|
      Time.parse(schedule['datetime']) > Time.parse(datetime)
    end
    
    if insert_position
      schedules.insert(insert_position, new_schedule)
    else
      schedules.push(new_schedule)
    end
    
    save_schedules(schedules)
    new_schedule
  end

  private

  def load_schedules
    return [] unless File.exist?(@schedule_file)
    
    JSON.parse(File.read(@schedule_file))
  rescue JSON::ParserError => e
    puts "Error parsing schedule file: #{e.message}"
    []
  end

  def save_schedules(schedules)
    File.write(@schedule_file, JSON.pretty_generate(schedules))
  end

  def find_active_tests(schedules, current_time)
    schedules.select do |schedule|
      schedule_time = Time.parse(schedule['datetime'])
      schedule_end = schedule_time + (schedule['duration'] * 60)
      
      # Test is active if current time is within the scheduled window
      current_time >= schedule_time && current_time < schedule_end &&
        schedule['status'] == 'scheduled'
    end
  end

  def execute_test(test)
    puts "Executing load test for team: #{test['team']}"
    puts "Test type: #{test['test_type']}"
    puts "Duration: #{test['duration']} minutes"
    puts "Contact: #{test['contact']}"
    
    # Mark as running
    test['status'] = 'running'
    test['started_at'] = Time.now.utc.iso8601
    
    # Here you would trigger your actual load testing infrastructure
    # For example: trigger_load_test(test)
    
    true
  end

  def cleanup_completed_tests(schedules, current_time)
    schedules.reject! do |schedule|
      schedule_time = Time.parse(schedule['datetime'])
      schedule_end = schedule_time + (schedule['duration'] * 60)
      
      # Remove tests that have finished
      if current_time >= schedule_end && schedule['status'] == 'running'
        schedule['status'] = 'completed'
        schedule['completed_at'] = current_time.iso8601
        puts "Completed test for team: #{schedule['team']}"
        
        # Keep completed tests for reporting (you might want to archive these)
        false # Don't remove completed tests immediately
      else
        false # Keep all other tests
      end
    end
  end

  def validate_business_hours(start_time, end_time)
    # Optional: Restrict to business hours (9 AM - 6 PM UTC, weekdays)
    start_hour = start_time.hour
    end_hour = end_time.hour
    weekday = start_time.wday
    
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
    
    if duration_minutes > max_duration
      raise "Test duration cannot exceed #{max_duration / 60} hours"
    end
    
    if duration_minutes < 15
      raise "Test duration must be at least 15 minutes"
    end
  end
end