# redirect the contents of all writes to @callback
class CallbackStd < File
    def initialize callback
        @callback = callback
    end

    def write text
        @callback.call(text)
    end
end