require './lib/base/position'

module Storage
  module Internal
    module Sources
      class Json < ::Base::Position
        def initialize; end

        def call
          [
              {
                id: "11",
                job_id: "2",
                status: "disabled",
                external_reference: nil,
                ad_description: "Description for campaign 11"
              },
              {
                id: "12",
                job_id: "2",
                status: "disabled",
                external_reference: "2",
                ad_description: "Description for campaign 12"
              },
              {
                id: "13",
                job_id: "3",
                status: "disabled",
                external_reference: "3",
                ad_description: "Description for campaign 133"
              }
          ]
        end
      end
    end
  end
end
