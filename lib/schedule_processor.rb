#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'time'
require_relative 'schedule_validator'

# Processes scheduled load tests and manages the schedule file
class ScheduleProcessor
  SCHEDULE_FILE = 'config/schedules.json'

  def initialize(schedule_file = SCHEDULE_FILE)
    @schedule_file = schedule_file
    @validator = ScheduleValidator.new
  end

  def process_current_schedule
    schedules = load_schedules
    current_time = Time.now.utc
    active_tests = find_active_tests(schedules, current_time)

    return process_active_tests(active_tests, schedules, current_time) if active_tests.any?

    puts 'No active tests scheduled for current time'
    1 # No tests to run
  end

  def validate_time_slot(requested_start, duration_minutes, team, schedules = nil)
    schedules ||= load_schedules
    @validator.validate_time_slot(requested_start, duration_minutes, team, schedules)
  end

  def add_schedule(schedule_params)
    schedules = load_schedules
    validate_time_slot(schedule_params[:datetime], schedule_params[:duration],
                       schedule_params[:team], schedules)

    new_schedule = create_schedule_entry(schedule_params)
    insert_schedule_chronologically(schedules, new_schedule)
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
      end
      false
    end
  end

  def process_active_tests(active_tests, schedules, current_time)
    puts "Active tests found: #{active_tests.size}"
    active_tests.each { |test| execute_test(test) }
    cleanup_completed_tests(schedules, current_time)
    save_schedules(schedules)
    0 # Success
  end

  def create_schedule_entry(params)
    base_schedule(params).merge(metadata_fields(params))
  end

  def base_schedule(params)
    {
      'datetime' => params[:datetime],
      'team' => params[:team],
      'duration' => params[:duration],
      'test_type' => params[:test_type],
      'contact' => params[:contact]
    }
  end

  def metadata_fields(params)
    {
      'slack_channel' => params[:slack_channel],
      'app_version' => params[:app_version],
      'expected_load' => params[:expected_load],
      'priority' => params[:priority] || 'P2',
      'status' => 'scheduled',
      'created_at' => Time.now.utc.iso8601
    }
  end

  def insert_schedule_chronologically(schedules, new_schedule)
    insert_position = schedules.find_index do |schedule|
      Time.parse(schedule['datetime']) > Time.parse(new_schedule['datetime'])
    end

    if insert_position
      schedules.insert(insert_position, new_schedule)
    else
      schedules.push(new_schedule)
    end
  end
end
