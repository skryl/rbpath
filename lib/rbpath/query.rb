class RbPath::Query
  include RbPath::Utils

  # takes a string query or a pre-parsed query list
  #
  def initialize(*query)
    @query = parse_query_list(query)
  end

  # Parsing rules:
  # - query keys are seperated by spaces, keys with spaces must be single quoted
  # - brackets group keys into an NOR group
  # - parens group keys into a OR group
  # - valid keys names consist of [chars|nums|spaces|-|_|.], anything else can
  #   be used as a seperator inside the parens/brackets
  #
  def parse_string_query(query)
    query.scan(/(\([^\)]+\)|\[[^\]]+\]|'[^']+'|[^\s]+)/)
         .flatten
         .map { |keys| { multi: /\*\*/ === keys[0..1],
                         neg:  /[\[\*]/ === keys[0],
                         keys: keys.scan(/[\w\d\s\-\_\.]+/) }}
  end

  def parse_query_list(query)
    query.flat_map do |part|
      case part
      when String, Symbol
        parse_string_query(part.to_s)
      when Regexp
        {multi: false, neg: false, keys: [], regexp: part}
      else {multi: false, neg: false, keys: [part]}
      end
    end
  end

  def query(data)
    data = deep_stringify_all(data)
    do_query(data, @query, [[]]).map(&:flatten)
                                .map { |path| get_value(data, path) }
  end

  def pquery(data)
    do_query(deep_stringify_all(data), @query, [[]]).map(&:flatten)
  end

  def values_at(data, paths)
    paths.map {|path| get_value(deep_stringify_all(data), path) }
  end

private

  def do_query(data, query, valid_paths)
    matcher, *rest = *query

    if query.empty? || valid_paths.empty?
      valid_paths
    elsif matcher[:multi]
       do_query(data, rest, valid_paths) +
         do_query(data, query, match(data, matcher, valid_paths))
    else
      do_query(data, rest, match(data, matcher, valid_paths))
    end
  end

  def match(data, matcher, valid_paths)
    neg, keys, rgx = matcher.values_at(:neg, :keys, :regexp)

    valid_paths.flat_map { |path| children = if rgx
                                      all_keys(data, path).grep(rgx)
                                    elsif neg
                                      (all_keys(data, path) - keys)
                                    else keys; end
                                  [path].product(children).map(&:flatten) } \
               .select   { |path| get_value(data, path) }
  end

  def all_keys(data, path)
    value = get_value(data, path)

    case value
    when Hash  then value.keys
    when Array then (0...value.size).map(&:to_s)
    when RbPath
      value.rbpath_fields
    else [value]
    end
  end

  def get_value(data, path)
    return data if path.empty?
    key, *rest = *path

    case data
    when Hash
      get_value(data[key], rest)
    when Array
      get_value(data[Integer(key)], rest) rescue nil
    when RbPath
      get_value(data.send(key), rest) if data.respond_to?(key)
    when key
      rest.empty? ? data : nil
    end
  end
end
