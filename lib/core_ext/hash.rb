class Hash
  # Like deep_symbolize_keys, but descends into arrays too
  def recursive_symbolize_keys
    inject({}) do |result, (key, value)|
      result[(key.to_sym rescue key) || key] = case value
      when Array
        value.map do |value|
          value.is_a?(Hash) ? value.deep_symbolize_keys : value
        end
      when Hash
        value.deep_symbolize_keys
      else
        value
      end
      result
    end
  end

  # Map hash to a hash, not an array
  def hmap(&block)
    Hash[self.map {|k, v| block.call(k,v) }]
  end

end