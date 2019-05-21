module Base
  class Position
    class << self
      def call(*args)
        new(*args).call
      end
    end
  end
end
