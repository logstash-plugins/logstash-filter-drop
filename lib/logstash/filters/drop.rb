# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

# Drop filter.
#
# Drops everything that gets to this filter.
#
# This is best used in combination with conditionals, for example:
# [source,ruby]
#     filter {
#       if [loglevel] == "debug" {
#         drop { }
#       }
#     }
#
# The above will only pass events to the drop filter if the loglevel field is
# `debug`. This will cause all events matching to be dropped.
class LogStash::Filters::Drop < LogStash::Filters::Base
  config_name "drop"
  # Drop all the events within a pre-configured percentage.
  #
  # This is useful if you just need a percentage but not the whole.
  #
  # Example, to only drop around 40% of the events that have the field loglevel with value "debug".
  #
  #     filter {
  #       if [loglevel] == "debug" {
  #         drop {
  #           percentage => 40
  #         }
  #       }
  #     }
  config :percentage, :validate => :number, :default => 100
  # Write any events that are dropped by this filter to the dead letter queue.
  #
  # The dead letter queue must be enabled for this feature to be useful using the Logstash setting
  # `dead_letter_queue.enable`.
  config :dlq_enabled, :validate => :boolean, :default => false
  # The reason to provide when writing this event to the dead letter queue. The sprintf format may
  # be used in this value.
  #
  # The `dlq_enabled` flag must be set to `true` for this value to take effect.
  config :dlq_reason, :validate => :string, :default => "Manually dropped"

  public
  def register
    @dlq_writer = dlq_enabled? ? execution_context.dlq_writer : nil
  end

  public
  def filter(event)
    if (@percentage == 100 || rand < (@percentage / 100.0))
      @dlq_writer.write(event, event.sprintf(@dlq_reason)) if @dlq_writer
      event.cancel
    end # if rand < @percentage
  end # def filter

  def dlq_enabled?
    # TODO there should be a better way to query if DLQ is enabled
    # See more in: https://github.com/elastic/logstash/issues/8064
    @dlq_enabled &&
      respond_to?(:execution_context) && execution_context.respond_to?(:dlq_writer) &&
      !execution_context.dlq_writer.inner_writer.is_a?(::LogStash::Util::DummyDeadLetterQueueWriter)
  end
end # class LogStash::Filters::Drop
