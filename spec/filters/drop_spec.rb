require "logstash/devutils/rspec/spec_helper"
require "logstash/filters/drop"

describe LogStash::Filters::Drop do

  let(:config) { Hash.new }
  subject { described_class.new(config) }

  let(:message) { "hello" }
  let(:event)   { LogStash::Event.new("message" => message) }

  describe "drop the event" do

    it "drops the event" do
      subject.register
      subject.filter(event)
      expect(event).to be_cancelled
    end

    context "when using percentage" do
      let(:config) { { "percentage" => 0 }}

      it "does not drop the event" do
        subject.register
        subject.filter(event)
        expect(event).not_to be_cancelled
      end

    end
  end
end
