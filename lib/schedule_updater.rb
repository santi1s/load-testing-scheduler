#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'schedule_processor'
require 'optparse'

class ScheduleUpdater
  def self.run(args = ARGV)
    options = parse_options(args)
    
    processor = ScheduleProcessor.new
    
    begin
      schedule = processor.add_schedule(
        options[:datetime],
        options[:team],
        options[:duration],
        options[:test_type],
        options[:contact],
        {
          slack_channel: options[:slack_channel],
          app_version: options[:app_version],
          expected_load: options[:expected_load],
          priority: options[:priority]
        }
      )
      
      puts "✅ Schedule added successfully:"
      puts JSON.pretty_generate(schedule)
      
      # Output for GitHub Actions
      puts "::set-output name=schedule_added::true"
      puts "::set-output name=team::#{schedule['team']}"
      puts "::set-output name=datetime::#{schedule['datetime']}"
      
    rescue StandardError => e
      puts "❌ Error adding schedule: #{e.message}"
      puts "::set-output name=schedule_added::false"
      puts "::set-output name=error::#{e.message}"
      exit 1
    end
  end

  def self.parse_options(args)
    options = {}
    
    OptionParser.new do |opts|
      opts.banner = "Usage: schedule_updater.rb [options]"
      
      opts.on("--datetime DATETIME", "Test start time (ISO8601: 2025-01-20T14:00:00Z)") do |v|
        options[:datetime] = v
      end
      
      opts.on("--team TEAM", "Team name") do |v|
        options[:team] = v
      end
      
      opts.on("--duration MINUTES", Integer, "Test duration in minutes") do |v|
        options[:duration] = v
      end
      
      opts.on("--test-type TYPE", "Test type (load, stress, spike, volume)") do |v|
        options[:test_type] = v
      end
      
      opts.on("--contact CONTACT", "Contact person (@username)") do |v|
        options[:contact] = v
      end
      
      opts.on("--slack-channel CHANNEL", "Slack channel for notifications") do |v|
        options[:slack_channel] = v
      end
      
      opts.on("--app-version VERSION", "Application version to test") do |v|
        options[:app_version] = v
      end
      
      opts.on("--expected-load LOAD", "Expected load description") do |v|
        options[:expected_load] = v
      end
      
      opts.on("--priority PRIORITY", "Priority (P0, P1, P2)") do |v|
        options[:priority] = v
      end
      
      opts.on("-h", "--help", "Show this help") do
        puts opts
        exit
      end
    end.parse!(args)
    
    # Validate required options
    required = [:datetime, :team, :duration, :test_type, :contact]
    missing = required.select { |key| options[key].nil? }
    
    unless missing.empty?
      puts "❌ Missing required options: #{missing.join(', ')}"
      exit 1
    end
    
    options
  end
end

# Run if called directly
if __FILE__ == $0
  ScheduleUpdater.run
end